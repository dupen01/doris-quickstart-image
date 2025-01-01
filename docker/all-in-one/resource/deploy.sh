#!/bin/bash
set -e

doris_log() {
    local type="$1"
    shift
    # accept argument string or stdin
    local text="$*"
    if [ "$#" -eq 0 ]; then text="$(cat)"; fi
    local dt="$(date -Iseconds)"
    printf '%s [%s] [Deploy]: %s\n' "$dt" "$type" "$text"
}
doris_note() {
    doris_log Note "$@"
}
doris_warn() {
    doris_log Warn "$@" >&2
}

hang_and_die(){
    sleeptime=15
    doris_warn "Will force shutdown in $sleeptime seconds ..."
    sleep $sleeptime
    supervisorctl shutdown
    exit 1
}

get_host_ip(){
    MYHOST=`ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}'`
    if [ -z $MYHOST ];then 
        echo 'Get IP Address failed!'
        exit 1
    else echo ""The IP Address is $MYHOST""
    fi 
}

get_host_ip

# check fe service aliveness
check_fe_liveness(){
    doris_note "Checking if FE service query port:9030 is alive or not ..."
    while true
    do
        NC="nc -z -w 5"
        if $NC $MYHOST 9030 ; then
            doris_note "FE service query port:9030 is alive!"
            break
        else
            doris_warn "FE service query port:9030 is NOT alive yet!"
            sleep 2
        fi
    done
}

MYSQL_CFG="-uroot -h $MYHOST -P9030 --batch"

exec_sql(){
    mysql $MYSQL_CFG -N -e "$@"
}

exec_sql_with_column(){
    mysql $MYSQL_CFG --column-names -e "$@"
}

exec_sql_with_retry(){
    local sql="$@"
    while true
    do
        result=`exec_sql "$@" 2>&1`
        ret=$?
        if [ $ret -eq 0 ] ; then
            echo "$result"
            return 0
        else
            errcode=`echo $result | awk -F " " '{print $2}'`
            if [[ $errcode = '1045' || $errcode = '1064' ]] ; then
                doris_warn "$PASSWD_ERROR_MSG"
                return 1
            else
                doris_warn "MySQL command fails with error: '$result', will try again"
            fi
        fi
        sleep 5
    done
}

check_and_add_be(){
    doris_note "Check if need to add BE into FE service ..."
    while true
    do
        result=`exec_sql_with_retry "SHOW BACKENDS;"`
        ret=$?
        if [ $ret -ne 0 ] ; then
            hang_and_die
        else
            if echo "$result" | grep -q $MYHOST &>/dev/null ; then
                doris_note "BE service already added into FE service ... "
                return 0
            else
                doris_note "Add BE($MYHOST:9050) into FE service ..."
                exec_sql_with_retry "ALTER SYSTEM ADD BACKEND '$MYHOST:9050';"
            fi
        fi
    done
}

check_fe_liveness
check_and_add_be
doris_note "Cluster initialization DONE!"
doris_note "Wait a few seconds for BE's heartbeat ..."
sleep 10
doris_note "Apache Doris Cluster information details:"
exec_sql_with_column 'SHOW FRONTENDS\G'
exec_sql_with_column 'SHOW BACKENDS\G'
# exec_sql_with_column 'SHOW BROKER\G'

echo 
echo 
doris_note "The Apache Doris Quickstart container has been started."

while true
do
    st=`supervisorctl status`
    running=`echo "$st" | grep RUNNING | wc -l`
    bad=`echo "$st" | grep -v RUNNING | wc -l`
    if [ $bad -gt 0 ] ; then
        doris_warn "has $bad services into non-RUNNING status!"
        doris_warn "$st"
    fi
    sleep 5
done
