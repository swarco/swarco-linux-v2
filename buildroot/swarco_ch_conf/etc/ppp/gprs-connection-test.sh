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

if [ -f /etc/default/gprs ]
then

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
