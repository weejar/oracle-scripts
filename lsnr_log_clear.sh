#!/bin/sh

# file: lsnr_log_clear.sh
# author: weejar(anbob.com)
# date: 2018/10/22
# desc: automatic to wrap listener log if filesize bigger than xx
# version: 1.6
# note: to add crontab in listener owner 
#
# I tested 11g, AIX 6, HPUX IA 11.31, EXADATA LINUX


# update history
# 0.1 2016/1/4 created
# ...
# 0.6 fix bug hpux 11.31  filesize over interger 2147483647 , do not work
# 0.7 fix bug hpux listener two processes, exclude "-inherit" one
# 0.8 fix bug hpux listener shadow processes get listener name wroung
# 0.9 fix bug filesize float type compare issue, to integer
# 1.0 fix LSNRRUNNING 
# 1.1 fix not remove listener xml log file in GRID HOME
# 1.2 fix LSNR LSNR_BIN path awk cut date or time
# 1.3 fix exclude another process contain "lsnr", et..  ETL tail listener log
# 1.5 fix get listener name,  get owner OH FOR each listener
# 1.6 check rm xml error

echo $0
echo  `date "+%Y-%m-%d %H:%M:%S"`
echo "lsnr_log_clear.sh V1.5"
echo "To clear listener log file begin..."  

WorkDir="/tmp"
listeners="${WorkDir}/listeners"

# unit Mb
FILESIZELIMIT=1024

# 0 not have xml, 1 have
XMLFLAG=0

# set env
if [[ -f ~/.profile ]]
then
. ~/.profile
fi

if [[ -f ~/.bash_profile ]]
then
. ~/.bash_profile
fi

if [[ ! -d $WorkDir ]]
then
   mkdir -p $WorkDir
fi

OSV=`uname -s`
echo "Current OS:${OSV}"

LSNRRUNNING=`ps -ef | grep tnslsnr |grep -v log| grep -v grep`
if [ -n "${LSNRRUNNING}" ]
then


  
# Get listener names
   ps -ef|grep lsnr|grep -v log|grep -v grep|sed 's/^.*\///'|awk '{print $2}'|sort |uniq  > ${listeners}

   
   
# Check user is listener owner
  
  USERID=`/usr/bin/id -u -nr`
  if [ $? -ne 0 ]
  then
      echo "ERROR: unable to determine uid" 
      exit 99
  fi
  
  echo "current user: ${USERID}"
  
  if [ -s "${listeners}" ] 
  then
    LSNROWNER=`ps -ef | grep tnslsnr |grep -v log| grep -v grep | grep -v -i scan|head -n 1|awk '{print $1}'`
    echo "listener owner: ${LSNROWNER}"
	

   
    if [ "${USERID}" != "${LSNROWNER}" ]
    then
       echo "ERROR: This script must be run as listener owner: ${LSNROWNER}"  
       exit 98
    fi
  fi
  
  
  if [ -s "${listeners}" ] 
  then
    for i in `cat ${listeners}|grep -v inherit`
    do
	    echo " "
        echo "listener name: ${i}"
        
		LSNROWNER=`ps -ef |grep "${i} "|grep -v grep|head -n 1|awk '{print $1}'`
		echo "listener owner: ${LSNROWNER}"
        if [ "${USERID}" != "${LSNROWNER}" ]
        then
           echo "ERROR: This script must be run as listener owner: ${LSNROWNER}, Skip!"  
		   continue
        fi
		
        # if lsnrctl ORACLE HOME NOT CURRENT, i.e. grid and oracle soft all use oracle user
        LSNR_BIN=`ps -ef|grep "${i} "|grep -v log|grep -v grep|head -n 1|awk '{print substr($0,index($0,"/"))}'`
		echo "Listener File Path: ${LSNR_BIN}"
		 
         if [ -n "${LSNR_BIN}" ]
         then
          ORACLE_HOME=${LSNR_BIN%/bin*}
         fi
         
         echo "Oracle Home: $ORACLE_HOME"

        
        LSNR_LOG=`${ORACLE_HOME}/bin/lsnrctl status ${i} | grep "Listener Log" | awk '{print $4}'`
        if [ ! -f "${LSNR_LOG}" ]
        then
          echo "${LSNR_LOG} get failed!"
          continue
        fi
        echo "listener log file: ${LSNR_LOG}"
        FILENAME=${LSNR_LOG##*/}
        echo  "listener filename: ${FILENAME}"
        FILEEXT=${FILENAME#*.}
        echo "listener file ext: ${FILEEXT}"
        
        
        if [[ "log" = "${FILEEXT}" ]]
         then 
             FILEPATH=`dirname ${LSNR_LOG}`
             echo "listener file path: ${FILEPATH}"
             FILESIZE=`ls -l ${LSNR_LOG}|awk '{ printf "%.0f", $5/1024/1024 }'`
             echo "listener file size(MB):${FILESIZE}"
			 if [ ${FILESIZE} -gt ${FILESIZELIMIT} ];then
              echo "listener log is bigger than ${FILESIZELIMIT} MB"
	          # cut listener log file
			  
${ORACLE_HOME}/bin/lsnrctl <<EOF
set cur listener ${i}
set log_status off
exit
EOF
			  
			  echo "cd ${FILEPATH}"
			  cd ${FILEPATH}
			  echo "mv -f ${FILENAME} ${FILENAME}_old"
			  mv -f ${FILENAME} ${FILENAME}_old
${ORACLE_HOME}/bin/lsnrctl <<EOF
set cur listener ${i}
set log_status on
exit
EOF
			  echo "gzip -f ${FILENAME}_old"
			  gzip -f ${FILENAME}_old
			 else
               echo "listener log  is litter than ${FILESIZELIMIT} MB"
             fi
        fi
              
        if [[ "xml" = "$FILEEXT" ]]
         then 
             LOGTXT="`echo ${i}|tr 'A-Z' 'a-z'`.log"
             LOGTXTPATH=`dirname ${LSNR_LOG} |sed 's/alert$/trace/'`
             LOGTXTFILE="$LOGTXTPATH/$LOGTXT"
             echo "listener txt log file: ${LOGTXTFILE}"
             FILESIZE=`ls -l ${LOGTXTFILE}|awk '{ printf "%.0f", $5/1024/1024 }'`
             echo "listener file size(MB):${FILESIZE}"
			 LOGXMLPATH=`dirname ${LSNR_LOG}`
			 echo "listener xml log Home: ${LOGXMLPATH}"
	     # curt txt file large than $FILESIZELIMIT
  	        if [ ${FILESIZE} -gt ${FILESIZELIMIT} ]
  	        then
                echo "listener log is bigger than ${FILESIZELIMIT} MB"
	              # cut listener log file
	              echo "mv -f ${LOGTXTFILE} ${LOGTXTFILE}_old "
	              mv -f ${LOGTXTFILE} ${LOGTXTFILE}_old
	              echo "cd ${LOGTXTPATH}"
	              cd ${LOGTXTPATH}
	              echo "gzip -f ${LOGTXT}_old"
	              gzip -f ${LOGTXT}_old
            else
               echo "listener log  is litter than ${FILESIZELIMIT} MB"
            fi
		 # curt xml logfile longer than 7 days.
             echo "To remove listener file for xml format longer than 7 days..."
			 cd $LOGXMLPATH
			 find ./ -name "log*.xml" -mtime +7 -print -exec rm {} \;
			   if [ $? -ne 0 ]
               then
                   echo "ERROR: unable to rm xml log" 
                   exit 94
               fi
         #set flag
	      XMLFLAG=1	
        fi
    done
  fi
else
  printf "Unable to swap listener log files - Listener down\n"
  echo "${HOST} Unable to swap listener log files - Listener down" 
fi

echo  `date "+%Y-%m-%d %H:%M:%S"`
echo "To clear listener log file completed!"  
echo  ""
echo  ""