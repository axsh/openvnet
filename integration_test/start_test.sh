#!/bin/bash
#

if [ "$1" == "-h" ] 
then
    echo "Usage: command <test_name> (<number of runs> <generate flow table diff>)"
    exit 0
fi

TEST=${1}
DIR=log/itest/current/${TEST}
COUNT=${2}
if [ -z ${COUNT} ]
then
COUNT=1
fi
FLOWS=${3}

COUNTER=0
while [ $COUNTER -lt ${COUNT} ]; do

  LOG_DIR=${DIR}

  bin/itest-spec run ${TEST} | tee log/output.log

  scp -r root@192.168.2.91:/var/log/openvnet/vna.log ${LOG_DIR}/itest1-vna.log
  scp -r root@192.168.2.91:/var/log/openvnet/webapi.log ${LOG_DIR}/itest1-webapi.log
  scp -r root@192.168.2.91:/var/log/openvnet/vnmgr.log ${LOG_DIR}/itest1-vnmgr.log
  scp -r root@192.168.2.92:/var/log/openvnet/vna.log ${LOG_DIR}/itest2-vna.log
  scp -r root@192.168.2.93:/var/log/openvnet/vna.log ${LOG_DIR}/itest3-vna.log
  ssh root@192.168.2.91 "mysqldump vnet >/tmp/db.dump"
  scp root@192.168.2.91:/tmp/db.dump ${LOG_DIR}/mysql.dump
  mv log/output.log ${LOG_DIR}/output.log

  if [ ! -z "${FLOWS}" ]
  then
    ./get_flow_diff.sh ${TEST}
  fi

  let COUNTER=COUNTER+1

done
