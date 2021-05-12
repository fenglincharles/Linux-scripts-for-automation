#!/bin/bash

. /home/acs/.profile > /dev/null 2>&1
			export sMAPDB=DASMAP
                        #export ACSDB=/home/acs/V11.0/DB
                        export ACSDB=/home/acs/V11.0/DB
                        export DIRDAS=$ACSDB/Convert/DAS
                        export ORACLE_HOST_BASEDB=$sMAPDB
                        export ORACLE_DBSTRING_BASEDB=$sMAPDB
                        export ORACLE_DBSTRING_SRCDB=$sMAPDB
                        export ORACLE_PW_SRCDB=acs

function nl_doc() {
                nl -n rz MASTERCFG.TXT
                }
cd $ACSDB/CONFIGURATION
        undbc -o MASTERCFG.DEF |tee -a $DIRDAS/MASTERCFG_add500.out
       
	nl_doc > MASTERCFG.TXT.nl
	for ((stationnum=401 ; stationnum<=680 ; stationnum=stationnum+1 ))
        do



                nu_head=$(nl -n rz MASTERCFG.TXT | grep "NO.:$stationnum"|awk '{print $1 }')
                #test20=$(echo "$nu_head+20"|bc -lq)
                nu_P=$(echo "$nu_head+8"|bc -lq)
                nu_R=$(echo "$nu_head+6"|bc -lq)
                nu_TR=$(echo "$nu_head+11"|bc -lq)
                nu_TP=$(echo "$nu_head+14"|bc -lq)
#########################################################
                RpointC=$(nl_doc |grep `printf '%06.0f' $nu_R`|awk '{print $4 }')
                RpointP=$(nl_doc |grep `printf '%06.0f' $nu_P`|awk '{print $4 }')
                RpointTR=$(nl_doc |grep `printf '%06.0f' $nu_TR`|awk '{print $4 }')
                RpointTP=$(nl_doc |grep `printf '%06.0f' $nu_TP`|awk '{print $4 }')

		RpointPNEW=$(echo "$RpointP+1000"|bc -lq)
		RpointTPNEW=$(echo "$RpointTP+1000"|bc -lq)
	
##########################################################
                OLDRrow=$(nl_doc |grep `printf '%06.0f' $nu_R`)
                OLDProw=$(nl_doc |grep `printf '%06.0f' $nu_P`)
                OLDTRrow=$(nl_doc |grep `printf '%06.0f' $nu_TR`)
		OLDTProw=$(nl_doc |grep `printf '%06.0f' $nu_TP`)
##########################################################
                #NEWRrow=$(nl_doc |grep `printf '%06.0f' $nu_R`|sed "s/= $RpointC/= $RpointP/gi")
               	#NEWProw=$(nl_doc |grep `printf '%06.0f' $nu_P`)
                #NEWTRrow=$(nl_doc |grep `printf '%06.0f' $nu_TR`|sed "s/= $RpointTR/= $RpointTP/gi")
                NEWProw=$(nl_doc |grep `printf '%06.0f' $nu_P`|sed "s/= $RpointP/= $RpointPNEW/gi")
                NEWTProw=$(nl_doc |grep `printf '%06.0f' $nu_TP`|sed "s/= $RpointTP/= $RpointTPNEW/gi")
		
#########################################################
                sed -i "s/$OLDProw/$NEWProw/gi" MASTERCFG.TXT.nl |tee -a $DIRDAS/MASTERCFG_add500.out
                sed -i "s/$OLDTProw/$NEWTProw/gi" MASTERCFG.TXT.nl |tee -a $DIRDAS/MASTERCFG_add500.out
#########################################################
		
	done      
		cat MASTERCFG.TXT.nl|awk '{print $2 FS $3 FS $4 FS $5 FS $6 FS $7 FS $8 FS $9}' > MASTERCFG.TXT
                echo "#########MASTERCFG.AUTO_FSTA.finish.txt generated!#########"
#                rm MASTERCFG.TXT.nl
                #rm MASTERCFG.AUTO_FSTA.finish.DEF
#                dc -o MASTERCFG.TXT |tee -a $DIRDAS/MASTERCFG_add500.out
                #mv MASTERCFG.AUTO_FSTA.finish.DEF MASTERCFG.DEF
                echo "#########MASTERCFG.AUTO_FSTA.finish.DEF -> MASTERCFG.DEF#########"|tee -a $DIRDAS/MASTERCFG_add500.out

