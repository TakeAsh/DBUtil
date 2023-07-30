#!/bin/bash

echo "dump all databases"
read -p "enter password for db-root: " Password

if [ ${#Password} -le 0 ]; then
  echo "aborted"
  exit 1
fi

Cmd=mariadb
CmdDump=mariadb-dump
FileDatabases=_Databases.txt
FileTables=_Tables.txt
read -r -d '' Opts <<EOL
[client]
user=root
password="${Password}"
default-character-set=utf8mb4
EOL

echo "${Opts}" \
  | ${Cmd} --defaults-extra-file=/dev/stdin -e "show databases;" \
  | tail -n +2 \
  > "${FileDatabases}"

exec 4< "${FileDatabases}"
while read Database 0<&4
do
  echo "# ${Database}"
  if [ ! -d ${Database} ]; then
    mkdir ${Database}
  fi
  pushd ${Database} > /dev/null
  echo "${Opts}" \
    | ${Cmd} --defaults-extra-file=/dev/stdin --database="${Database}" -e "show tables;" \
    | tail -n +2 \
    > "${FileTables}"
  exec 5< "${FileTables}"
  while read Table 0<&5
  do
    echo "- ${Table}"
    echo "${Opts}" \
      | ${CmdDump} --defaults-extra-file=/dev/stdin --force "${Database}" "${Table}" \
      > "${Table}.sql"
  done
  exec 5<&-
  popd > /dev/null
done
exec 4<&-
