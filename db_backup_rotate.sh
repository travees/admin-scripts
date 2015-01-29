#!/bin/sh

dump_dir="/tmp"
dump_file="db.dump"
gzip=1
dumps_to_keep=10

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

mysqldump -u ${MYSQL_USER} -p${MYSQL_PASS} -P${MYSQL_PORT} -h ${MYSQL_HOST} ${MYSQL_DB} >> ${dump_dir}/${dump_file}.tmp || {
  echo "Dump command failed"
  exit 1
} 


while [ $dumps_to_keep -ne 1 ]
do
  let dump_to_mv=$dumps_to_keep-1
  old_file="${dump_dir}/${dump_file}.${dump_to_mv}${suffix}"
  new_file="${dump_dir}/${dump_file}.${dumps_to_keep}${suffix}"

  if [ -e ${dump_dir}/${dump_file}.${dump_to_mv}${suffix} ]
  then
    mv $old_file $new_file || {
      echo "Could not move $old_file to $new_file"
      exit 1
    }
  fi
  let dumps_to_keep=$dumps_to_keep-1
done

mv ${dump_dir}/${dump_file}.tmp ${dump_dir}/${dump_file}.1
if [ $gzip ]
then
  gzip $dump_dir/$dump_file.1
fi
