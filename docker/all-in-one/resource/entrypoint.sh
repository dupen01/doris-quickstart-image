#!/bin/bash
set -e

DORIS_HOME="/opt/apache-doris"


init_conf(){
    set -e
    # 获取默认网关地址
    route=`ip route get 8.8.8.8 | sed -n 1p | awk '{print $3}'`
    PRIORITY_NETWORKS=$route"/24"
    if [ -z $PRIORITY_NETWORKS ];then 
        echo 'Get priority_networks failed!'
        exit 1
    else echo ""The priority_networks values is $PRIORITY_NETWORKS""
    fi 

    # 更新配置文件
    fe_priority_networks_cnt=$(cat $DORIS_HOME/fe/conf/fe.conf | sed -n '/^priority_networks.*/p' | wc -l)
    if [ $fe_priority_networks_cnt -gt 0 ];then 
        sed -i '/^priority_networks.*/d' $DORIS_HOME/fe/conf/fe.conf
    else echo "priority_networks = ${PRIORITY_NETWORKS}" >> $DORIS_HOME/fe/conf/fe.conf
    fi
    
    be_priority_networks_cnt=$(cat $DORIS_HOME/be/conf/be.conf | sed -n '/^priority_networks.*/p' | wc -l)
    if [ $fe_priority_networks_cnt -gt 0 ];then 
        sed -i '/^priority_networks.*/d' $DORIS_HOME/be/conf/be.conf
    else echo "priority_networks = ${PRIORITY_NETWORKS}" >> $DORIS_HOME/be/conf/be.conf
    fi

    
}

init_conf

exec supervisord -n -c /etc/supervisor/supervisord.conf
