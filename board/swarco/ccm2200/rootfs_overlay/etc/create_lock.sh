#*****************************************************************************
#* 
#*  @file          /etc/create_lock
#*
#*                 shell script helper function for creating 
#*                 a lock to ensure the only one instance of the script
#*                 is running at a time
#*                 2015 SWARCO Traffic Systems GmbH
#*
#*  @version       0.1
#*  @date          <2005-09-05 17:03:03 gc>
#*  @author        Guido Classen
#* 
#*  @par change history:
#*    2015-06-08 gc: initial version 
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
      logger -t "'$1'" "Removing lock. Exit: $ECODE"
      rm -rf "${LOCKDIR}"' 0 1 2 3 15
    echo "$$" >"${PIDFILE}"
}

