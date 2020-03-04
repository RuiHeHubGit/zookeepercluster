#!/usr/bin/env bash

NODE_TOTAL=3
ONLY_DOWN="false"
ONLY_SHOW_STATUS="false"

function print_help() {
    echo "Options: [-h|--help] [-t|--nodeTotal <num>] [--down] [--status]"
}

function get_params() {
    while true; do
        case $1 in
                -h|--help)
                print_help
                exit 0
                ;;
                -t|--nodeTotal)
                shift; NODE_TOTAL=$1; shift; continue
                ;;
                --down)
                ONLY_DOWN="true"; shift; continue
                ;;
                --status)
                ONLY_SHOW_STATUS="true"; shift; continue
                ;;
                #no more args
                "")
                break
                ;;
                #unknown args, show help
                *)
                print_help
                exit 1
                ;;
        esac
    done
}

function generate_compose_conf() {
    if [[ ${NODE_TOTAL} -ne 3 && ${NODE_TOTAL} -gt 0 ]]; then
        DOCKER_COMPOSE_CONF="docker-compose.yml"
        echo "generate ${DOCKER_COMPOSE_CONF}"
        ZOO_SERVERS=""
        for ((i=1; i<=${NODE_TOTAL}; i++))
        do
            ZOO_SERVERS="${ZOO_SERVERS} server.${i}=zoo${i}:2888:3888"
        done

        echo "version: '3.1'" > ${DOCKER_COMPOSE_CONF}
        echo "services:" >> ${DOCKER_COMPOSE_CONF}
        for ((i=1; i<=${NODE_TOTAL}; i++))
        do
            echo "  zoo${i}:" >> ${DOCKER_COMPOSE_CONF}
            echo "    build: ." >> ${DOCKER_COMPOSE_CONF}
            echo "    restart: always" >> ${DOCKER_COMPOSE_CONF}
            echo "    hostname: zoo${i}" >> ${DOCKER_COMPOSE_CONF}
            echo "    container_name: zookeeper_${i}" >> ${DOCKER_COMPOSE_CONF}
            echo "    ports:" >> ${DOCKER_COMPOSE_CONF}
            echo "      - $((2180+i)):2181" >> ${DOCKER_COMPOSE_CONF}
            echo "    volumes:" >> ${DOCKER_COMPOSE_CONF}
            echo "      - /usr/local/docker_app/zookeeper/zoo${i}/data:/tmp/zookeeper/data" >> ${DOCKER_COMPOSE_CONF}
            echo "      - /usr/local/docker_app/zookeeper/zoo${i}/datalog:/tmp/zookeeper/datalog" >> ${DOCKER_COMPOSE_CONF}
            if [[ ${NODE_TOTAL} -gt 1 ]]; then
                echo "    environment:" >> ${DOCKER_COMPOSE_CONF}
                echo "      ZOO_MY_ID: ${i}" >> ${DOCKER_COMPOSE_CONF}
                echo "      ZOO_SERVERS: ${ZOO_SERVERS}" >> ${DOCKER_COMPOSE_CONF}
            fi
            echo "" >> ${DOCKER_COMPOSE_CONF}
        done
    else
     cp docker-compose-default.yml docker-compose.yml
    fi
}

function show_status() {
    # print zookeeper server status
    echo "zookeeper server status:"
    LINE_NUM=1
    docker-compose ps | while read LINE
    do
            if [[ ${LINE_NUM} -eq 1 ]]; then
                    echo -e "${LINE}\t\t\tMode"
            elif [[ ${LINE_NUM} -eq 2 ]]; then
                    echo "${LINE}-------------"
            else
                    C_NAME="$(echo ${LINE} | awk '{print $1}')"
                    ZK_MODE="$(docker exec ${C_NAME} ./bin/zkServer.sh status 2>&1 | tee zk_mode.txt >/dev/null && tail -n 1 zk_mode.txt | awk '{print $2}')"
                    echo -e "${LINE}\t${ZK_MODE}"
            fi
            ((LINE_NUM++))
    done
}

function install_docker() {
	echo "check docker ..."
	docker -v
    if [[ $? -eq  0 ]]; then
        echo "docker already installed"
    else
    	echo "install docker ..."
        curl -sSL https://get.daocloud.io/docker | sh
        echo "install docker completed"

        docker -v

        if [[ $? -ne  0 ]]; then
            echo "Install docker failed"
            return 1
        fi
    fi

    return 0
}

function download_zookeeper() {
    wget http://apache.fayea.com/zookeeper/zookeeper-3.4.9/zookeeper-3.4.9.tar.gz
    if [[ $? -ne  0 ]]; then
        echo "download zookeeper failed"
        return 1
    fi
}

function install_docker-compose() {
	echo "check docker-compose ..."
	docker-compose -v
    if [[ $? -ne  0 ]]; then
        echo "docker-compose already installed"
    else
    	echo "install docker-compose ..."
    	sudo curl -L https://github.com/docker/compose/releases/download/1.8.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
        sudo chmod a+x /usr/local/bin/docker-compos
        echo "install docker-compose completed"

        docker-compose -v

        if [[ $? -ne  0 ]]; then
            echo "install docker-compose failed"
            return 1
        fi
    fi

    return 0
}

function init_env() {
    install_docker
    if [[ $? -ne  0 ]]; then
        exit 1
    fi

    sudo systemctl enable docker
    sudo systemctl start docker

    install_docker-compose
    if [[ $? -ne  0 ]]; then
        exit 1
    fi

    download_zookeeper
    if [[ $? -ne  0 ]]; then
        exit 1
    fi
}

function main() {

    init_env

    get_params $@

    if [[ ${ONLY_SHOW_STATUS} ]]; then
        if [[ ! -f docker-compose.yml ]]; then
            generate_compose_conf
        fi
        show_status
        exit 0
    fi

    if [[ ${NODE_TOTAL} -le 0 || ${NODE_TOTAL} -ge 12 ]]; then
        echo "The total number of nodes is allowed from 1 to 11."
        echo "Please reset the appropriate total to run."
        exit 1
    fi

    if [[ "${ONLY_DOWN}" == "true" ]]; then
        if [[ ! -f docker-compose.yml ]]; then
            generate_compose_conf
        fi
        docker-compose down
        exit 0
    fi

    generate_compose_conf

    docker-compose build

    docker-compose up -d

    sleep 10s

    show_status
}

main $@