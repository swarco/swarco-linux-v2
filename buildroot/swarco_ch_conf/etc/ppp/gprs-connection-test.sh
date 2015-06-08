#!/bin/sh
#*****************************************************************************
#* 
#*  @file          gprs-connection-test.sh
#*
#*  This script is started periodically by a cronjob an tests the
#*  availibility of the GPRS network connection.
#*
#*  @version       1.0 (\$Revision$)
#*  @author        Guido Classen <br>
#*                 SWARCO Traffic Systems GmbH
#* 
#*  $LastChangedBy$  
#*  $Date$
#*  $URL$
#*
#*  @par Modification History:
#*    2011-01-19 gc: initial version
#*  
#*****************************************************************************

create_lock() {
    LOCKDIR="/var/lock/$1.lock"
    PIDFILE="${LOCKDIR}/PID"

    while ! mkdir "${LOCKDIR}" &>/dev/null
    do
    # lock failed, now check if the other PID is alive
        OTHERPID="$(cat "${PIDFILE}")"

    # if cat wasn't able to read the file anymore, another instance probably is
    # about to remove the lock -- exit, we're *still* locked
        if [ $? != 0 ]; then
            echo "lock failed, PID ${OTHERPID} is active" >&2
            exit 1
        fi

        if kill -0 $OTHERPID &>/dev/null; then
        # lock is valid and OTHERPID is active - exit, we're locked!
            logger -t "$1" "lock failed, PID ${OTHERPID} is active"
            exit 1
        fi

    # lock is stale, remove it and restart
        logger -t "$1" "removing stale lock of nonexistant PID ${OTHERPID}"
        rm -rf "${LOCKDIR}"
    done


    trap 'ECODE=$?;
      logger -t "$1" "Removing lock. Exit: $ECODE"
      rm -rf "${LOCKDIR}"' 0 1 2 3 15
    echo "$$" >"${PIDFILE}"

}


if [ -f /etc/default/gprs ]
then
    create_lock gprs-connection-test

    . /etc/default/gprs
    
    if [ \! -z "$GPRS_CON_TEST_TCP_HOSTS" ]; then
        for host in $GPRS_CON_TEST_TCP_HOSTS
        do
            local port=${host##*:}
            host=${host%%:*}
            echo running nc $host $port
            if nc $host $port </dev/null 2>&1 >/dev/null; then
                logger -t $0 "netcat to $host:$port successfully"
                if [ -f /etc/ppp/gprs-okay.sh ]; then
                    sh /etc/ppp/gprs-okay.sh
                fi
                exit 0
            fi
            logger -t $0 "netcat to $host:$port FAILED"    

        done
    fi

    if [ \! -z "$GPRS_CON_TEST_PING_HOSTS" ]; then

        logger -t $0 "start pinging hosts"
        for host in $GPRS_CON_TEST_PING_HOSTS
        do
            if ping -q -c 3 -w 120 $host 2>&1 >/dev/null; then
                logger -t $0 "ping to $host successfully"
                if [ -f /etc/ppp/gprs-okay.sh ]; then
                    sh /etc/ppp/gprs-okay.sh
                fi
                exit 0
            fi
            logger -t $0 "ping to $host FAILED"    
        done
        
        logger -t $0 "pinging all connection test hosts FAILED"
        if [ -f /etc/ppp/gprs-fail.sh ]; then
            sh /etc/ppp/gprs-fail.sh
        fi      
    fi

fi

exit 0
