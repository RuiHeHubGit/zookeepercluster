#!/usr/bin/env bash

SERVER_OP="restart"
UPDATE_CONF=true
MY_ID=${ZOO_MY_ID}
SERVERS=${ZOO_SERVERS}
DATA_DIR=${ZK_DATA_DIR}
BASE_DIR=${ZOOKEEPER_BASE}

case $0 in
"start")
SERVER_OP=$0
;;
"start-foreground")
SERVER_OP=$0
;;
"stop")
SERVER_OP=$0
UPDATE_CONF="false"
;;
"restart")
SERVER_OP=$0
;;
"status")
SERVER_OP=$0
UPDATE_CONF="false"
;;
esac

cd ${BASE_DIR}

if [[ "$UPDATE_CONF" == "true" ]]; then
    cp conf/zoo_sample.cfg conf/zoo.cfg

    sed -i "s#dataDir=.*#dataDir=${DATA_DIR}#g" conf/zoo.cfg

    if [[ -n ${MY_ID} && -n ${SERVERS} ]]; then
        touch ${DATA_DIR}/myid
        echo ${MY_ID} > ${DATA_DIR}/myid

        OLD_IFS="$IFS"
        IFS=" "
        array=(${SERVERS})
        IFS="$OLD_IFS"
        for ser in ${array[@]}
        do
          echo ${ser} >> conf/zoo.cfg
        done
    fi
fi

./bin/zkServer.sh ${SERVER_OP}