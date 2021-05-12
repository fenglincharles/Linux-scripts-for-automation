#!/bin/bash
######
#		 PROCEDURE_FOR_CRONTAB.sh 
#			
#Create by/date CL/2060722
######
#set -x 
#trap "" 1 2 3
. /users/acs/.profile > /dev/null 2>&1
date
export DIRMAPS=/home/acs/DB/DASDB/MAPS
export sMAPDB=DASMAP
export ACSDB=/home/acs/V10/DB
export DIRDAS=$ACSDB/Convert/DAS
export ORACLE_HOST_BASEDB=$sMAPDB
export ORACLE_DBSTRING_BASEDB=$sMAPDB
export ORACLE_DBSTRING_SRCDB=$sMAPDB
export ORACLE_PW_SRCDB=acs
##function
function pause(){
	read -n 1 -p "$*" INP
        if [ $INP != '' ] ; then
			echo -ne '\b \n'
        fi
}
## Check required file 
cd $DIRMAPS
A=$(echo RUN_CONVERT_AUTO.sh)
B=$(echo Get_DXFList_ALL.sh)
C=$(echo Get_DXFList_INC.sh)
D=$(echo DB_GISMAP_UPDATE_AUTO.sh)
find $A $B $C $D > /dev/null 2>&1;echo $?>Check
R=$(cat Check)
if [ $R -eq 1 ];then 
echo -e "The following scripts might lost,please check ! \nRUN_CONVERT_AUTO.sh \nGet_DXFList_ALL.sh\nGet_DXFList_INC.sh\nDB_GISMAP_UPDATE_AUTO.sh"
pause
exit 0
fi
## check trigger 

cd $DIRMAPS
DXF_trigger=$(ls -al |grep "DXF_BILK.txt\|DXF_INCR.txt")
DXF_trigger_Cnt=$(ls -al |grep "DXF_BILK.txt\|DXF_INCR.txt"|wc -l)
while [ "$DXF_trigger_Cnt" -lt "2" ]
do
	case $DXF_trigger in
	"DXF_BILK.txt")
		$DIRDAS/RUN_CONVERT_AUTO.sh blk
		rm DXF_BILK.txt DXF_INCR.txt
		exit 0
		;;
	"DXF_INCR.txt")
		$DIRDAS/RUN_CONVERT_AUTO.sh inc
		rm DXF_BILK.txt DXF_INCR.txt
		exit 0
		;;
	*)
		echo "CONVERT PROCESS DETECTION DONE, NO NEW DATA FOUND"
		exit 0
		;;
	esac
done
echo -e "There are mutiple triger found ! please check the state of DXF_BULK.txt or DXF_INCR.txt "
pause 'Press any key to exit process'
exit 0








