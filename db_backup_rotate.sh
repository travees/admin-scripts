#!/bin/bash

umask 0077

storage_dir="~"
tmp_dir="/tmp"
gzip=1
dumps_to_keep=5

prefix=""
if [ $gzip ]
then
  suffix=".gz"
fi

MYSQL_USER="dbuser"
MYSQL_PASS="dbpass"
MYSQL_DB="dbnames"
MYSQL_HOST="dbhost"
MYSQL_PORT=3306

for _db in $MYSQL_DB
do
  echo "-- `date +%Y%m%d`" > "${tmp_dir}/$_db.tmp"
  mysqldump -u ${MYSQL_USER} -p${MYSQL_PASS} -P${MYSQL_PORT} -h ${MYSQL_HOST} ${_db} >> "${tmp_dir}/${_db}.tmp" || {
    echo "Dump command failed"
    exit 1
  } 


  while [ $dumps_to_keep -ne 1 ]
  do
    let dump_to_mv=$dumps_to_keep-1
    old_file="${storage_dir}/${_db}.${dump_to_mv}${suffix}"
    new_file="${storage_dir}/${_db}.${dumps_to_keep}${suffix}"

    if [ -e "${storage_dir}/${_db}.${dump_to_mv}${suffix}" ]
    then
      mv "$old_file" "$new_file" || {
        echo "Could not move $old_file to $new_file"
        exit 1
      }
    fi
    let dumps_to_keep=$dumps_to_keep-1
  done

  mv "${tmp_dir}/${_db}.tmp" "${storage_dir}/${_db}.1"
  if [ $gzip ]
  then
    gzip "${storage_dir}/$_db.1"
  fi
done
