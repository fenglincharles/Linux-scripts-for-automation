#!/bin/bash
############################################################################################
#					AUTO Fake STAtion Generator (AUTO_FSTA) 
#
#
#
#Function: 			Generate Fake station for FDIR testing propose automatically 
#Process:			1.Keyin station number for inserting fakepoints/testSTATION.ufid 1,2
#					2.Generate Tables&Points in MAPDB  
#					3.Convert point by DasToDB at inserted Fakestation
#					4.Modify LIBs
#					5.Modify MASTERCONFIG.DEF
#Rely tables:		1.GIS_SWITCH		%SWTYPE="SWT"
#					2.GIS_SUBSTATION
#					3.GIS_BREAKER
#					4.DAS_RTDB
#					5.DAS_RTDBCONTROL
#					6.DAS_DEFAULT
#
#
#Required file:		AUTO_FSTA_point.sql
#					AUTO_sample.txt
#
#Generation of table1.DAS_RTDB_FAKESTATION
#					2.DAS_RTDB_FSTA_DUP_BK (This table contains redundant old points after AUTO_FSTA)
#					  DAS_RTDB_CTRL_FSTA_DUP_BK
#					3.DAS_FAKESTATIONNUM
#					4.DAS_RTDBCONTROL_FAKESTATION
#					5.DAS_RTDB_FSTA_OPTIONAL_DEVICES
#
#Created by/created date:					CL/201605
#Enviroment:								LINUX 5 PRISM 10.01 Oracle 10
#Last modified by/Last modified date:		CL/20160914
#Log :20160914 Change user interaction and  cut off funtion of USE_Old_STATION duo to the lack of effectiveness
############################################################################################
#Description:
#1.SQL for Switch total number check:
#select b.ufid, a.substation,count(*) from gis_switch a ,gis_substation b  where a.substation=b.name group by  b.ufid, a.substation
#
#2.
#update gis_switch a set substation=(select substation from tb_switch_subsname b 
#	where b.ufid=a.ufid and b.substation not like 0 ) where a.substation is null;
#
#For some version of bash, it might not support "read -p" commend ,note about it
############################################################################################
## process control#########################################
	CREATE_FS_DAS_RTDB=1	
	USE_Old_STATION=0   
	ENABLE_Fpoint_to_Das_RTDB=1
	#Append sample Devicetype into Lib file
	CREATE_FS_DEF=1
	#
	Move_P_to_R=1
	Modify_MASTERCONFIG=1

#trap "" 1 2 3
. /users/acs/.profile > /dev/null 2>&1
#set -x
echo "#########`date` :Start AUTO_FSTA#########" |tee /home/acs/V11.0/DB/Convert/DAS/AUTO_FSTA.out
if [ $CREATE_FS_DAS_RTDB = 1 ]; then
		echo "NOTICE!the fakestation number must be less than 10000"
		echo -n "Please keyin: "
		read B
		echo -e "\nNotice! If you have not opt any testsation for test propose."
		echo -e "You can Press [Enter] and skip this funtion\n"
		#echo -e "You can find the SQL script in the Descript of AUTO_FSTA.sh\n"
		echo -e "Please keyin UFID of two Substations you want for testing FDIR propose\n"
		echo -n "(Ex:123 124):"
		read C D
		## parameter setting######################################
			stationnuminput=$B
			stationnuminput2=$(echo "$B-1"|bc -lq)
			stationnuminput3=$(echo "$B-2"|bc -lq)
			teststationUFID1=$C
			teststationUFID2=$D
			
		if [ "$stationnuminput" == "" -o "$stationnuminput2" == "" ]; then 
				echo "#########fakestation is not avaliable, please check!#########"
				exit 0 
		fi
		if [ "$teststationUFID1" == "" -o "$teststationUFID2" == "" ]; then 
				#echo -e "If you DON'T want to load old UFID of two Substations,Type S"
				#echo -n "(S):"
				#read E
				#if [ $E == "S" -o $E == "s" ]; then
					teststationUFID1=-999
					teststationUFID2=-999
				#else
				#	USE_Old_STATION=1
				#fi
		fi
		## parameter setting######################################
			dp -d 129
			export sMAPDB=DASMAP
			#export ACSDB=/home/acs/V11.0/DB
			export ACSDB=/home/acs/V11.0/DB
			export DIRDAS=$ACSDB/Convert/DAS
			export ORACLE_HOST_BASEDB=$sMAPDB
			export ORACLE_DBSTRING_BASEDB=$sMAPDB
			export ORACLE_DBSTRING_SRCDB=$sMAPDB
			export ORACLE_PW_SRCDB=acs
		### Check MAPDB Connection################################
		echo "#########MAPDB: $ORACLE_USER_SRCDB/$ORACLE_PW_SRCDB@$ORACLE_DBSTRING_SRCDB ..."|tee -a $DIRDAS/AUTO_FSTA.out
		sqlplus $ORACLE_USER_SRCDB/$ORACLE_PW_SRCDB@$ORACLE_DBSTRING_SRCDB << END_MAPDB_TEST |tee END_MAPDB_TEST.tmp
END_MAPDB_TEST
		echo "###############################################################"
			MAPDB_TEST=$(cat END_MAPDB_TEST.tmp | grep ERROR -i)
		if [ -z "$MAPDB_TEST" ]; then
			echo "#########DASMAP Oracle connected ...,NO ERROR#########" |tee -a $DIRDAS/AUTO_FSTA.out
			rm END_MAPDB_TEST.tmp
			sqlplus -s $ORACLE_USER_SRCDB/$ORACLE_PW_SRCDB@$ORACLE_DBSTRING_SRCDB << For_firsttime_use >null
			create table das_rtdb_FSTA_dup_BK as select * from das_rtdb where tablename='ABC';
			create table das_rtdb_CTRL_FSTA_dup_BK as select * from das_rtdbcontrol where tablename='ABC';
			create table DAS_RTDB_FSTA_OPTIONAL_DEVICES as select TABLENAME,EQUIP_NUM from das_rtdb where tablename='ABC';
			create table Das_FakestationNUM (stationnum varchar2(10) not null,stationnum2 varchar2(10) not
			null);
			exit;
For_firsttime_use
		else
			echo "#########DASMAP Oracle may not able to connected ..., ERROR generated,please check!" |tee -a $DIRDAS/AUTO_FSTA.out
			cat END_MAPDB_TEST.tmp
			exit 0
			#InfoBox "Check MAPDB Oracle Connection!!!" 10 &
		fi
		echo "###############################################################"
#if [ $CREATE_FS_DAS_RTDB = 1 ]; then
		cd $DIRDAS
		echo "#########Generate table Das_FakestationNUM ..."
		echo "set echo on;" > AUTO_FSTA_Generated.sql
		echo "delete das_RTDB where station=(select stationnum from Das_FakestationNUM);" >> AUTO_FSTA_Generated.sql
		echo "delete das_RTDB where station=(select stationnum2 from Das_FakestationNUM);" >> AUTO_FSTA_Generated.sql
		echo "create table das_tmp_FSTA_NUM as select * from Das_FakestationNUM;" >> AUTO_FSTA_Generated.sql
		echo "drop table Das_FakestationNUM;" >> AUTO_FSTA_Generated.sql
		echo "create table Das_FakestationNUM (stationnum VARCHAR2(10),stationnum2 VARCHAR2(10),stationnum3 VARCHAR2(10),teststationUFID1 VARCHAR2(10),teststationUFID2 VARCHAR2(10));" >> AUTO_FSTA_Generated.sql	
		if [ $USE_Old_STATION = 1 ]; then
			echo "insert into Das_FakestationNUM (stationnum,stationnum2,stationnum3,teststationUFID1,teststationUFID2) values ("$stationnuminput","$stationnuminput2","$stationnuminput3","$stationnuminput","$stationnuminput2");" >> AUTO_FSTA_Generated.sql
			echo "update Das_FakestationNUM set teststationUFID1=(select teststationUFID1 from das_tmp_FSTA_NUM),teststationUFID2=(select teststationUFID2 from das_tmp_FSTA_NUM);" >> AUTO_FSTA_Generated.sql
		else
			echo "insert into Das_FakestationNUM (stationnum,stationnum2,stationnum3,teststationUFID1,teststationUFID2) values ("$stationnuminput","$stationnuminput2","$stationnuminput3","$teststationUFID1","$teststationUFID2");" >> AUTO_FSTA_Generated.sql
		fi
		echo "delete das_RTDB where station=(select stationnum from Das_FakestationNUM);" >> AUTO_FSTA_Generated.sql
		echo "delete das_RTDB where station=(select stationnum2 from Das_FakestationNUM);" >> AUTO_FSTA_Generated.sql
		echo "delete das_RTDB where station=(select stationnum3 from Das_FakestationNUM);" >> AUTO_FSTA_Generated.sql
		echo "delete das_RTDBCONTROL where CTRLstation=(select stationnum from Das_FakestationNUM);" >> AUTO_FSTA_Generated.sql
		echo "delete das_RTDBCONTROL where CTRLstation=(select stationnum from das_tmp_FSTA_NUM);" >> AUTO_FSTA_Generated.sql
		echo "drop table das_tmp_FSTA_NUM;" >> AUTO_FSTA_Generated.sql
		echo "commit;" >> AUTO_FSTA_Generated.sql
			if [ -f $DIRDAS/AUTO_FSTA_point.sql ]; then
				strings $DIRDAS/AUTO_FSTA_point.sql >> AUTO_FSTA_Generated.sql
			echo "#########Generate_table_das_RTDB_fakestation on MAPDB: $ORACLE_USER_SRCDB/$ORACLE_PW_SRCDB@$ORACLE_DBSTRING_SRCDB ..."
			sqlplus $ORACLE_USER_SRCDB/$ORACLE_PW_SRCDB@$ORACLE_DBSTRING_SRCDB @"AUTO_FSTA_Generated.sql" >> $DIRDAS/AUTO_FSTA.out
			else 
				echo "#########AUTO_FSTA_point.sql not existed,please check#########"|tee -a $DIRDAS/AUTO_FSTA.out
				echo "#########AUTO_FSTA runs failed#########" |tee -a $DIRDAS/AUTO_FSTA.out
				exit 0
			fi
else
	ENABLE_Fpoint_to_Das_RTDB=0
	Move_P_to_R=0
	Modify_MASTERCONFIG=0
fi

if [ $ENABLE_Fpoint_to_Das_RTDB = 1 ]; then	
	echo "#########Update_table_das_RTDB_fakestation to Das_RTDB & LOCREMFLAG into DAS_DEFAULT..."
##Back up the duplicated point in DAS_RTDB&DAS_RTDBCONTROL table (for the first time user)
	sqlplus $ORACLE_USER_SRCDB/$ORACLE_PW_SRCDB@$ORACLE_DBSTRING_SRCDB << das_rtdb_FSTA_dup_BK >> $DIRDAS/AUTO_FSTA.out
	set echo on;
	insert into das_rtdb_FSTA_dup_BK select * from das_RTDB where tablename||'x'||equip_num||'x'||colname in (select tablename||'x'||equip_num||'x'||colname from das_RTDB_fakestation);
	insert into das_rtdb_CTRL_FSTA_dup_BK select * from das_RTDBCONTROL where tablename||'x'||equip_num||'x'||colname in (select tablename||'x'||equip_num||'x'||colname from das_RTDB_fakestation);
das_rtdb_FSTA_dup_BK
##Insert Fpoint into DAS_RTDB&DAS_RTDBCONTROL table
	sqlplus $ORACLE_USER_SRCDB/$ORACLE_PW_SRCDB@$ORACLE_DBSTRING_SRCDB << fakestation_part_two > AUTO_Fpoint_to_Das_RTDB_result
F
	delete das_RTDB where tablename||'x'||equip_num||'x'||colname in (select tablename||'x'||equip_num||'x'||colname from das_RTDB_fakestation);
	insert into das_RTDB select * from das_RTDB_fakestation where enableflag=1;
	delete das_RTDBcontrol a where tablename||'x'||equip_num||'x'||colname in (select tablename||'x'||equip_num||'x'||colname from das_RTDBcontrol_fakestation); 
	insert into das_RTDBcontrol select * from das_RTDBcontrol_fakestation where enableflag=1;
	commit;
	exit;
fakestation_part_two
	Fakestation_RTDBTEST=$(cat AUTO_Fpoint_to_Das_RTDB_result | grep ERROR -i)
	if [ -z "$Fakestation_RTDBTEST" ]; then
			echo "#########Das_RTDB and Das_RTDB_fakestation are well synchonized ,NO ERROR" |tee -a $DIRDAS/AUTO_FSTA.out
			cat AUTO_Fpoint_to_Das_RTDB_result >> AUTO_FSTA.out
			rm AUTO_Fpoint_to_Das_RTDB_result
	else
			echo "#########ERROR generated on inserting Das_RTDB_fakestation to DAS_RTDB" |tee -a $DIRDAS/AUTO_FSTA.out
			echo "#########Open AUTO_Fpoint_to_Das_RTDB_result tmpfile .." |tee -a $DIRDAS/AUTO_FSTA.out
			cat AUTO_Fpoint_to_Das_RTDB_result |tee -a $DIRDAS/AUTO_FSTA.out
			rm AUTO_Fpoint_to_Das_RTDB_result
			echo "#########NOTICE! DAS_RTDB NOT being inserted with fakepoints, please check AUTO_FSTA.out" |tee -a $DIRDAS/AUTO_FSTA.out
			echo "#########AUTO_FSTA runs failed#########" |tee -a $DIRDAS/AUTO_FSTA.out
			exit 0
	fi
else
	if [ $CREATE_FS_DAS_RTDB = 0 ]; then
	echo "Pass FP insert process"|tee -a $DIRDAS/AUTO_FSTA.out
	else
	echo "NOTICE! DAS_RTDB NOT being inserted with fakepoints, please check flag ENABLE_Fpoint_to_Das_RTDB" |tee -a $DIRDAS/AUTO_FSTA.out
	echo "#########AUTO_FSTA runs failed#########" |tee -a $DIRDAS/AUTO_FSTA.out
	exit 0
	fi
fi
## Do DasTODB for fakeststion with P point and control point
##DasToDB -o -nc -DasMap -st $stationnum | tee $DIRDAS/$output_file
if [ $CREATE_FS_DEF = 1 ]; then

	###### Auto insert SW_CTRL,CAP_CTRL into Control LIB	
	echo "#########Start inset SW_CTRL into CTRL lib #########" |tee -a $DIRDAS/AUTO_FSTA.out
	cd $DIRDAS
	Samplefile=$(ls |grep AUTO_SAMPLE*)
	if [ -f $Samplefile ]; then
			cp -p AUTO_SAMPLE.txt $ACSDB/CONTROL/.
			cp -p AUTO_SAMPLE.txt $ACSDB/STATUS/.
			cp -p AUTO_SAMPLE.txt $ACSDB/TELEMETRY/.
			cd $ACSDB/CONTROL/.
			cp -p CTLSTS.LIB CTLSTS.LIB.AUTO_FSTA.BK
			undbc -o CTLSTS.LIB |tee -a $DIRDAS/AUTO_FSTA.out
##			cat CTLSTS.TXT |grep device |awk '{print $3}'|sed 's/"//g'
##			|egrep 'SW_CTRL|CAP_CTRL|TAP_CTRL|LTCLOCK_CTRL|LOCLTCLOCK_CTRL' >tmpname
			cat CTLSTS.TXT |grep AUTO_FSTA_FLAG > tmpname
			if [ -s tmpname ]; then
				echo "#########Basic DeviceType has verified in CTLSTS.LIB#########" |tee -a $DIRDAS/AUTO_FSTA.out
			else
				head -n 57 AUTO_SAMPLE.txt >> CTLSTS.TXT
				head -n 57 AUTO_SAMPLE.txt > CAP_CTRL.tmp
				cat CAP_CTRL.tmp |sed 's/SW_CTRL/CAP_CTRL/g' >> CTLSTS.TXT
				cat CAP_CTRL.tmp |sed 's/SW_CTRL/TAP_CTRL/g' >> CTLSTS.TXT
				cat CAP_CTRL.tmp |sed 's/SW_CTRL/LTCLOCK_CTRL/g' >> CTLSTS.TXT
				cat CAP_CTRL.tmp |sed 's/SW_CTRL/LOCLTCLOCK_CTRL/g' >> CTLSTS.TXT
				cat CAP_CTRL.tmp |sed 's/SW_CTRL/AUTO_FSTA_FLAG/g' >> CTLSTS.TXT
				#sed -i "s/SW_CTRL/CAP_CTRL/gi" CAP_CTRL.tmp
				#cat CAP_CTRL.tmp >> CTLSTS.TXT
				dbc CTLSTS.TXT
				mv CTLSTS.DEF CTLSTS.LIB
			fi
			rm tmpname
			rm CAP_CTRL.tmp
			
			
			
			
			
			
			
			
			
			
			
			
##			Add Telemetry auto_sample as required in the future ##
		if [ $TELEMETRY_DEF == 1 ]; then
			cd $ACSDB/TELEMETRY/.
			cp -p TELEMETRY.LIB TELEMETRY.LIB.AUTO_FSTA.BK
			undbc -o TELEMETRY.LIB |tee -a $DIRDAS/AUTO_FSTA.out
##			cat TELEMETRY.TXT |grep device |awk '{print $3}'|sed 's/"//g'
##			|egrep 'SW_CTRL|CAP_CTRL|TAP_CTRL|LTCLOCK_CTRL|LOCLTCLOCK_CTRL' >tmpname
			cat TELEMETRY.TXT |grep AUTO_FSTA_FLAG > tmpname
			if [ -s tmpname ]; then
				echo "#########Basic DeviceType has verified in TELEMETRY.LIB#########" |tee -a $DIRDAS/AUTO_FSTA.out
			else
				
				head -n 57 AUTO_SAMPLE.txt >> TELEMETRY.TXT
				head -n 57 AUTO_SAMPLE.txt > CAP_CTRL.tmp
				cat CAP_CTRL.tmp |sed 's/SW_CTRL/CAP_CTRL/g' >> TELEMETRY.TXT
				cat CAP_CTRL.tmp |sed 's/SW_CTRL/TAP_CTRL/g' >> TELEMETRY.TXT
				cat CAP_CTRL.tmp |sed 's/SW_CTRL/LTCLOCK_CTRL/g' >> TELEMETRY.TXT
				cat CAP_CTRL.tmp |sed 's/SW_CTRL/LOCLTCLOCK_CTRL/g' >> TELEMETRY.TXT
				cat CAP_CTRL.tmp |sed 's/SW_CTRL/AUTO_FSTA_FLAG/g' >> TELEMETRY.TXT
				#sed -i "s/SW_CTRL/CAP_CTRL/gi" CAP_CTRL.tmp
				#cat CAP_CTRL.tmp >> TELEMETRY.TXT
				dbc TELEMETRY.TXT
				mv TELEMETRY.DEF TELEMETRY.LIB
			fi
			rm tmpname
			rm CAP_CTRL.tmp		
		fi
			
			
			
			

			
			
			
			
			
			cd $ACSDB/STATUS/.
			cp -p STATUS.LIB STATUS.LIB.AUTO_FSTA.BK
			undbc -o STATUS.LIB |tee -a $DIRDAS/AUTO_FSTA.out
##			cat STATUS.TXT |grep device |awk '{print $3}'|sed 's/"//g'
##			|egrep 'ACS_(BREAKER|FUSE|MXFMR|TRANS|SUBSTATION|RECLOSER|REGULATOR|SWITCH|LOAD|GENERATOR)
##			|STASTATUS|FAULTFLAG|RECLLOCKFLAG|LOCREMFLAG|LTCLOCK|LOCLTCLOCK|VCLOCKFLAG|TAP'>tmpname
			cat STATUS.TXT |grep AUTO_FSTA_FLAG > tmpname
			if [ -s tmpname ]; then
			echo "#########Basic DeviceType has verified in STATUS.LIB#########"|tee -a $DIRDAS/AUTO_FSTA.out
			else
			nu_tmp=$(cat AUTO_SAMPLE.txt |wc -l)
			nu_tmp2=$(echo "$nu_tmp-57"|bc -lq)
			tail -n $nu_tmp2 AUTO_SAMPLE.txt >> STATUS.TXT
			dbc STATUS.TXT
			mv STATUS.DEF STATUS.LIB
			fi
			rm tmpname
	else
		echo "#########AUTO_FSTA_sample.txt not existed, process STATUS.LIB&CTLSTS.LIB with alternative procedure!#########"|tee -a $DIRDAS/AUTO_FSTA.out
		cd $ACSDB/CONTROL
		cp -p CTLSTS.LIB CTLSTS.LIB.AUTO_FSTA.BK
		undbc -o CTLSTS.LIB |tee -a $DIRDAS/AUTO_FSTA.out
		tail -n 57 CTLSTS.TXT > CTRL_model.tmp
		cat CTLSTS.TXT > CTLSTS.AUTO_FSTA.TXT
		OLDCROW=$(strings CTRL_model.tmp|grep device|tee CTRL_model.tmp2)

		if [ -s CTRL_model.tmp2 ];then
			NEWCROW=$(cat CTRL_model.tmp2|sed 's/".*"/"SW_CTRL"/gi'|tee CTRL_model.tmp2)
			sed -i "s/$OLDCROW/$NEWCROW/gi" CTRL_model.tmp
			old_nu=$(strings CTRL_model.tmp|grep NO|awk 'BEGIN{FS=":"}{print $2}')
			new_nu=$(echo "$old_nu+1"|bc -lq)
			OLD_NO_ROW=$(strings CTRL_model.tmp|grep NO)
			NEW_NO_ROW=$(strings CTRL_model.tmp|grep NO|sed "s/[0-9][0-9]/$new_nu/g")
			echo "#########NEW Device NO in Control LIB is $NEW_NO_ROW"|tee -a $DIRDAS/AUTO_FSTA.out
			sed -i "s/$OLD_NO_ROW/$NEW_NO_ROW/g" CTRL_model.tmp
			cat	CTRL_model.tmp >> CTLSTS.AUTO_FSTA.TXT
			rm CTLSTS.AUTO_FSTA.DEF
			dbc CTLSTS.AUTO_FSTA.TXT|tee -a $DIRDAS/AUTO_FSTA.out
			mv CTLSTS.AUTO_FSTA.DEF CTLSTS.LIB
			echo "#########Finish inset SW_CTRL into CTRL lib #########"
			rm CTRL_model.tmp*
		else
			echo "#########Somthing wrong with CONTROL lib, please check#########"
		fi
	fi
	if [ $CREATE_FS_DAS_RTDB = 1 ]; then
	cd $ACSDB/STATUS
	echo "#########Start DasToDB ...#########"
	DasToDB -o -DasMap -st $stationnuminput >> $DIRDAS/AUTO_FSTA.out
	DasToDB -o -DasMap -st $stationnuminput2 >> $DIRDAS/AUTO_FSTA.out
	DasToDB -o -DasMap -st $stationnuminput3 >> $DIRDAS/AUTO_FSTA.out
	sqlplus $ORACLE_USER_SRCDB/$ORACLE_PW_SRCDB@$ORACLE_DBSTRING_SRCDB << das_P_to_R |tee -a $DIRDAS/AUTO_FSTA.out
	set echo on;
	update das_rtdb set category='R' where tablename||'x'||equip_num||'x'||colname in (select tablename||'x'||equip_num||'x'||colname from das_RTDB_fakestation) and tablename ='SWITCH';
	commit;
	exit;
das_P_to_R
	echo "#########Finish DasToDB#########"
	else
	echo "Create LIBs process completed only, Other process are infuntional due to Process control, please check AUTO_FSTA.sh!"|tee -a $DIRDAS/AUTO_FSTA.out
	echo "#########AUTO_FSTA. Completed!#########"|tee -a $DIRDAS/AUTO_FSTA.out
	fi
	
fi
## Changing files from P to R 		
if [ $Move_P_to_R = 1 ]; then
	for stationnum in $stationnuminput $stationnuminput3
	do
		cd $ACSDB/STATUS
		SPfilname=$(ls -al | awk '{print $9}' |grep 0$stationnum.DEF$ |grep P)
		if	[ -f $SPfilname ]; then 
			SRfilname=$(echo $SPfilname | sed -e 's/P/R/g')
			cp -p $ACSDB/STATUS/$SPfilname $ACSDB/STATUS/$SPfilname.AUTO_FSTA_BK
			mv $ACSDB/STATUS/$SPfilname $ACSDB/STATUS/$SRfilname
			echo "######### $SRfilname generated!#########"
		else
			echo "#########STATUS$stationnum.DEF not existed,please check#########" |tee -a $DIRDAS/AUTO_FSTA.out
			echo "#########AUTO_FSTA runs failed#########" |tee -a $DIRDAS/AUTO_FSTA.out
			exit 0
		fi
		cd $ACSDB/TELEMETRY
		TPfilname=$(ls -al | awk '{print $9}' |grep 0$stationnum.DEF$ |grep P)
		if	[ -f $TPfilname ]; then 
			TRfilname=$(echo $TPfilname | sed -e 's/P/R/g')
			cp -p $ACSDB/TELEMETRY/$TPfilname $ACSDB/TELEMETRY/$TPfilname.AUTO_FSTA_BK
			mv $ACSDB/TELEMETRY/$TPfilname $ACSDB/TELEMETRY/$TRfilname
			echo "######### $TRfilname generated!#########"
		else
			echo "#########TELEMETRY$stationnum.DEF not existed,please check#########" |tee -a $DIRDAS/AUTO_FSTA.out
			echo "#########AUTO_FSTA runs failed#########" |tee -a $DIRDAS/AUTO_FSTA.out
			exit 0
		fi
	done
fi

## Modify Masterconfig
if [ $Modify_MASTERCONFIG = 1 ]; then
	cd $ACSDB/CONFIGURATION
	cp -p MASTERCFG.DEF MASTERCFG.DEF.AUTO_FSTA.BK
	undbc -o MASTERCFG.DEF |tee -a $DIRDAS/AUTO_FSTA.out
	for stationnum in $stationnuminput $stationnuminput3
	do
		nu_head=$(nl -n rz MASTERCFG.TXT | grep "NO.:$stationnum"|awk '{print $1 }')

		#test20=$(echo "$nu_head+20"|bc -lq)
		nu_P=$(echo "$nu_head+8"|bc -lq)
		nu_R=$(echo "$nu_head+6"|bc -lq)
		nu_TR=$(echo "$nu_head+11"|bc -lq)
		nu_TP=$(echo "$nu_head+14"|bc -lq)
		function nl_doc() {
		nl -n rz MASTERCFG.TXT
		}
		RpointC=$(nl_doc |grep `printf '%06.0f' $nu_R`|awk '{print $4 }') 
		RpointP=$(nl_doc |grep `printf '%06.0f' $nu_P`|awk '{print $4 }')
		RpointTR=$(nl_doc |grep `printf '%06.0f' $nu_TR`|awk '{print $4 }')
		RpointTP=$(nl_doc |grep `printf '%06.0f' $nu_TP`|awk '{print $4 }')

		OLDRrow=$(nl_doc |grep `printf '%06.0f' $nu_R`)
		OLDProw=$(nl_doc |grep `printf '%06.0f' $nu_P`)
		OLDTRrow=$(nl_doc |grep `printf '%06.0f' $nu_TR`)

		NEWRrow=$(nl_doc |grep `printf '%06.0f' $nu_R`|sed "s/= $RpointC/= $RpointP/gi")
		#NEWProw=$(nl_doc |grep `printf '%06.0f' $nu_P`)
		NEWTRrow=$(nl_doc |grep `printf '%06.0f' $nu_TR`|sed "s/= $RpointTR/= $RpointTP/gi")
		nl_doc > MASTERCFG.TXT.nl

		sed -i "s/$OLDRrow/$NEWRrow/gi" MASTERCFG.TXT.nl |tee -a $DIRDAS/AUTO_FSTA.out
		#sed -i "s/$OLDProw/$NEWProw/gi" MASTERCFG.TXT.nl |tee -a $DIRDAS/AUTO_FSTA.out
		sed -i "s/$OLDTRrow/$NEWTRrow/gi" MASTERCFG.TXT.nl |tee -a $DIRDAS/AUTO_FSTA.out
		cat MASTERCFG.TXT.nl|awk '{$1="";sub(/[  ]/,"");print $0 }' > MASTERCFG.TXT
		#cat MASTERCFG.TXT.nl|awk '{print $2 FS $3 FS $4 FS $5 FS $6 FS $7 FS $8 FS $9 FS $10 FS $11 FS $12 FS $13 FS $14 FS $15 FS $16}' > MASTERCFG.TXT
		#cat MASTERCFG.TXT.nl|awk 'BEGINF{}{ for ( i=2; i<=NF; i++) print $i}' > MASTERCFG.TXT #Wrong, it will breake the records.
		echo "#########MASTERCFG.AUTO_FSTA.finish.txt ,N.O $stationnum generated!#########"
		rm MASTERCFG.TXT.nl
	done
		#rm MASTERCFG.AUTO_FSTA.finish.DEF
		dbc -o MASTERCFG.TXT |tee -a $DIRDAS/AUTO_FSTA.out
		#mv MASTERCFG.AUTO_FSTA.finish.DEF MASTERCFG.DEF
		echo "#########MASTERCFG.AUTO_FSTA.finish.DEF -> MASTERCFG.DEF#########"|tee -a $DIRDAS/AUTO_FSTA.out
fi
echo "###############################################################"
read -p "`date` , Finish AUTO_FSTA ,Do you want to reset PRISM? (y/n) :" A
if [ $A == "y" -o $A == "Y" ]; then
	STOPPRISM
	STARTPRISM
fi
cd $DIRDAS
cat $DIRDAS/AUTO_FSTA.out| egrep "Device Type|Control Device File"|uniq >$DIRDAS/AUTO_FSTA_checkDeviceType.out
if [ -s $DIRDAS/AUTO_FSTA_checkDeviceType.out ]; then
	echo "#########Some DeviceType not found!,please check AUTO_FSTA_checkDeviceType.out"|tee -a $DIRDAS/AUTO_FSTA.out
else
	rm $DIRDAS/AUTO_FSTA_checkDeviceType.out
fi
echo "#########AUTO_FSTA. Completed!#########"




