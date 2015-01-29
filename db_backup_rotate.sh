#!/bin/sh

umask 0077

storage_dir="~"
tmp_dir="/tmp"
dump_file="db.dump"
gzip=1
dumps_to_keep=5

prefix=""
if [ $gzip ]
then
  suffix=".gz"
fi

echo "-- `date +%Y%m%d`" > $dump_dir/$dump_file.tmp
MYSQL_USER="dbuser"
MYSQL_PASS="dbpass"
MYSQL_DB="dbname"
MYSQL_HOST="dbhost"
MYSQL_PORT=3306

mysqldump -u ${MYSQL_USER} -p${MYSQL_PASS} -P${MYSQL_PORT} -h ${MYSQL_HOST} ${MYSQL_DB} >> "${tmp_dir}/${dump_file}.tmp" || {
  echo "Dump command failed"
  exit 1
} 


while [ $dumps_to_keep -ne 1 ]
do
  let dump_to_mv=$dumps_to_keep-1
  old_file="${storage_dir}/${dump_file}.${dump_to_mv}${suffix}"
  new_file="${storage_dir}/${dump_file}.${dumps_to_keep}${suffix}"

  if [ -e "${storage_dir}/${dump_file}.${dump_to_mv}${suffix}" ]
  then
    mv "$old_file" "$new_file" || {
      echo "Could not move $old_file to $new_file"
      exit 1
    }
  fi
  let dumps_to_keep=$dumps_to_keep-1
done

mv "${tmp_dir}/${dump_file}.tmp" "${storage_dir}/${dump_file}.1"
if [ $gzip ]
then
  gzip "${storage_dir}/$dump_file.1"
fi
