#clean_archivelogs.sh

ORACLE_BASE=/opt/oracle/orauser
ORACLE_HOME=/opt/oracle/orauser/product/dbms/19c
ORACLE_SID=$1
#export CREDO=`grep $ORACLE_SID /home/orauser/.admin/.credo | awk '{print $2}'`

export ORACLE_BASE ORACLE_HOME ORACLE_SID

PATH=/bin:$ORACLE_HOME/bin:$PATH
export PATH

#. $HOME/.bash_profile
export TNS_ADMIN=${ORACLE_BASE}/admin/${ORACLE_SID}/tnsadmin
logfile=/home/orauser/scripts/arch_cleanup/clean_archivelogs.log

#######################################################################################
## 20210312 - Script Modification                                                    ##
## Patrick O'Regan                                                                   ##
## used=`df -H /oralogs | grep -vE '^Filesystem'|awk '{ print $5 }'|cut -d'%' -f1`;  ##
##                                                                                   ##
## Replacement code to use PERCENT_SPACE_USED instead of drive space listed above    ##
#######################################################################################

PercentUsed=$(

echo "
#select PERCENT_SPACE_USED as "" from v\$flash_recovery_area_usage where file_type = 'ARCHIVED LOG';" | sqlplus -s system/$CREDO@$ORACLE_SID | column | awk '{ print int($3) }'
select PERCENT_SPACE_USED as "" from v\$flash_recovery_area_usage where file_type = 'ARCHIVED LOG';" | sqlplus -s / as sysdba | column | awk '{ print int($3) }'
)

############################################
##  let "used2=$used";   Replaced below:  ##
############################################

let "PercentUsed2=$PercentUsed";

rman=`ps -ef|grep ou_rman_backup|wc -l`;

if [ $PercentUsed2 -ge 45 ]; then
# if [ $PercentUsed2 -ge 05 ]; then

  if [ $rman = 1 ]; then

    echo `date` ":   rman is not running! so let's clean up the archive logs!" >> $logfile 2>&1

/nfs/oracle_sys_share/oracle.dba/scripts_std/backup/ou_rman_backup.sh $ORACLE_SID ARCH DISK >> $logfile 2>&1

  else

    echo `date` ":   rman is already running!" >> $logfile 2>&1

  fi

  else

  echo `date` ":   using < 45% of flash_recovery_area_usage. Skipping run" >> $logfile 2>&1

fi

if [ $PercentUsed2 -ge 80 ]; then
# if [ $PercentUsed2 -ge 05 ]; then
	echo "Your archive space on $ORACLE_SID is critical" |mailx -s "Archive space critical on $ORACLE_SID" valupada@ohio.edu
fi
