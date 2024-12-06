#!/bin/bash

# hosts.txt 书写格式
#
# 192.168.1.123：app:db:end
#

BACKUP_PATH="/media/backup/"

PASSWD_FILE="/etc/rsyncd.passwd"

# 以“:”分隔，第一位写源主机ip，后面接着rsync服务中配置的要备份的模块，最后以end结尾，一行一条
DATAS=$(cat ${BACKUP_PATH}/hosts.txt)

function dobackup() {
  for DATA in ${DATAS[@]}; do
    for ((i=0;i<15;i++)) {
      temp=$(echo ${DATA} | awk -F ':' -v p="$[${i}+1]" '{print $p}')
	  DATE=$(date '+%Y-%m-%d')
	  FILEPATH=${temp}"_"${DATE}
      if [ ${i} == 0 ]; then
        if [ ! -d ${BACKUP_PATH}/${temp} ]; then
          mkdir ${BACKUP_PATH}/${temp}
	      chmod 777 ${BACKUP_PATH}/${temp}
	    fi
        HOST=${temp}
		continue
	  fi
	    
	  if [ "${temp}"x = "end"x ]; then
        break
	  fi

      if [ ! -d ${BACKUP_PATH}/${HOST} ]; then
      	mkdir -p ${BACKUP_PATH}/${HOST}/${FILEPATH}
	chmod 777 ${BACKUP_PATH}/${HOST}/${FILEPATH}
	rsync -az --append-verify --copy-unsafe-links --password-file=${PASSWD_FILE}  rsync@${HOST}::${temp}/ ${BACKUP_PATH}/${HOST}/${FILEPATH}/
	ln -s ${BACKUP_PATH}/${HOST}/${FILEPATH} ${BACKUP_PATH}/${HOST}/${temp}"_latest"
	exit 0
      fi

      mkdir -p ${BACKUP_PATH}/${HOST}/${FILEPATH}
      chmod 777 ${BACKUP_PATH}/${HOST}/${FILEPATH}
      rsync -az --delete-delay --append-verify --copy-unsafe-links --password-file=${PASSWD_FILE} --link-dest ${BACKUP_PATH}/${HOST}/${temp}"_latest"  rsync@${HOST}::${temp}/ ${BACKUP_PATH}/${HOST}/${FILEPATH}/
	  wait
	  ISEXIST=$(ls ${BACKUP_PATH}/${HOST}/${FILEPATH}/ | wc -l)
	  if [ ${ISEXIST} -ne 0 ]; then
	    echo "${HOST} backup success"
	    rm -f ${BACKUP_PATH}/${HOST}/${temp}"_latest"
	    ln -s ${BACKUP_PATH}/${HOST}/${FILEPATH} ${BACKUP_PATH}/${HOST}/${temp}"_latest"
            cd ${BACKUP_PATH}/${HOST}/
            rm -rf $(ls -l | grep ${temp}_ | head -n -8)
	    wait
            cd $HOME
	  else
	    find ${BACKUP_PATH}/${HOST}/ -maxdepth 1 -type d -empty -delete
	    echo "${HOST} backup failed"
	  fi
	}
  done
}

dobackup
