#!/bin/bash

# hosts.txt 书写格式
#
# /app
# /home/abc/aaa
#

BACKUP_PATH="/media/backup/"

# 写需要备份的文件或文件夹路径，一行一条，末尾不要带“/”
DATAS=$(cat ${BACKUP_PATH}/hosts.txt)

function dobackup() {
  for DATA in ${DATAS[@]}; do
    temp=${DATA}
    NAME=$(echo ${DATA} | awk -F '\/' '{print $NF}')
    DATE=$(date '+%Y-%m-%d')
    FILEPATH=${NAME}"_"${DATE}
	    
    if [ ! -d ${BACKUP_PATH}/${NAME} ]; then
      mkdir -p ${BACKUP_PATH}/${NAME}
      chmod 777 ${BACKUP_PATH}/${NAME}
      rsync -az --append-verify --copy-unsafe-links ${temp}/ ${BACKUP_PATH}/${NAME}/${FILEPATH}/
      ln -s ${BACKUP_PATH}/${NAME}/${FILEPATH} ${BACKUP_PATH}/${NAME}/${NAME}"_latest"
    fi


    rsync -az --delete-delay --append-verify --copy-unsafe-links --link-dest ${BACKUP_PATH}/${NAME}/${NAME}"_latest" ${temp}/ ${BACKUP_PATH}/${NAME}/${FILEPATH}/
    wait
    ISEXIST=$(ls ${BACKUP_PATH}/${NAME}/${FILEPATH}/ | wc -l)
    if [ ${ISEXIST} -ne 0 ]; then
      echo "${NAME} backup success"
      rm -f ${BACKUP_PATH}/${NAME}/${NAME}"_latest"
      ln -s ${BACKUP_PATH}/${NAME}/${FILEPATH} ${BACKUP_PATH}/${NAME}/${NAME}"_latest"
      if [ ${BACKUP_PATH}x != ""x ];then
        cd ${BACKUP_PATH}/${NAME}
      else
	echo "cannot find backup path!"
	exit 1
      fi
      rm -rf $(ls -l | grep ${NAME}_ | head -n -8)
      wait
      cd $HOME
    else
      if [ ${BACKUP_PATH}x != ""x ];then
        find ${BACKUP_PATH}/${NAME}/ -maxdepth 1 -type d -empty -delete
      fi
      echo "${NAME} backup failed"
    fi
  done
}

dobackup
