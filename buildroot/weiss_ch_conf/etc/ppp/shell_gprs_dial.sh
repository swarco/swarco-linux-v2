#!/bin/sh

#GPRS_DEVICE=/dev/ttyS0
#GPRS_DEVICE=/dev/com1
#GPRS_BAUDRATE=115200
#. /etc/default/gprs
#GPRS_DEVICE=/dev/com1

cr=`echo -n -e "\r"`

error() {
    print "Reseting terminal adapter"
    if [ ! -z "$GPRS_RESET_CMD" ]; then
        /bin/sh -c "$GPRS_RESET_CMD"
        sleep 20
    else
        case $TA_VENDOR in
            SIEMENS)
                at_cmd "AT+CFUN=1,1"
                sleep 60
                ;;
            *)
                print "Don't known how to reset terminal adapter $TA_VENDOR"
                ;;
        esac
    fi

    exit 1
}

send() {
  print "SND: $1"
  echo -e "$1\r" >&3 &
}


wait_quiet() {
  print "wait_quiet $1"
  local wait_time=2
  if [ "$1" -gt 0 ]; then wait_time=$1; fi

  local line=""
  while read -t$wait_time line<&3
  do
      #remove trailing carriage return
      line=${line%%${cr}*}
      print "RCV: $line"
  done
  return 0
}


# execute AT cmd and wait for "OK"
# Params: 1 AT Command String
#         2 Wait time in seconds (default 10)
#         3 Additional WAIT string
# Result $r Result string
at_cmd() {
  # r is returned to called
  r=""
  local wait_time=2
  local count=0
  local wait_str="----------------------------------------------"

  if [ "$2" -gt 0 ]; then wait_time=$2; fi
  if [ ! -z "$3" ]; then wait_str="$3"; fi

  print "SND: $1"
  echo -e "$1\r" >&3 &

#  sleep $wait_time
  
  while true
  do
      local line=""
      if ! read -t$wait_time line<&3
      then
          print timeout
          return 2
      fi
      #remove trailing carriage return
      line=${line%%${cr}*}
      print "RCV: $line"
      r="$r $line"
      case $line in
          *OK*)
              return 0
              ;;
          *${wait_str}*)
              print "got wait: $wait_str"
              return 0
              ;;
             
          *ERROR*)
              return 1
              ;;
      esac
      count=$(($count+1))
      if [ $count -gt 15 ]
      then
          print timeout
          return 2
      fi
  done

  if [ -d /proc/$! ]; then echo TTY driver hangs; return 3; fi
  return 0
}

# print log message
print() {
    echo $*
}

##############################################################################
# Check if TTY device does not block after open 
##############################################################################

print "Starting GPRS connection on device $GPRS_DEVICE ($GPRS_BAUDRATE baud)"

# prevent blocking when opening the TTY device due modem status lines
stty -F $GPRS_DEVICE clocal -crtscts

echo x <$GPRS_DEVICE&
sleep 5
if [ -d /proc/$! ]; then 
    echo TTY driver hangs; 
    reboot
    exit 3; 
fi

print "Terminal adapter responses on AT command"


if ! stty -F $GPRS_DEVICE $GPRS_BAUDRATE -brkint -icrnl -imaxbel -opost -onlcr -isig -icanon -echo -echoe -echok -echoctl -echoke 2>&1 ; then

    # stty may say "no such device"
    print "stty failed"
    killall watchdog
    reboot &
    error

fi
# connect file handle 3 with terminal adapter
exec 3<>$GPRS_DEVICE

print "ready"

for l in 1 2 3 4 5 
do
    if at_cmd "AT"; then
        print okay
        break
    else
        at_cmd "+++" 5 "NO CARRIER"
    fi

    if [ $l == "5" ]; then
        error
    fi
done

##############################################################################
# Check vendor / model of connected terminal adapter
##############################################################################

at_cmd "ATi" || error
print res: $r
case $r in
    *SIEMENS*)
        TA_VENDOR=SIEMENS
        case $r in
            *MC35*)
                TA_MODEL=MC35
                print "Found Siemens MC35 GPRS terminal adapter"
                ;;
            *HC25*)
                TA_MODEL=HC25
                print "Found Siemens HC25 UMTS/GPRS terminal adapter"
                # HC25: enable network (UTMS=blue/GSM=green) status LEDs
                at_cmd "AT^sled=1"
                ;;
            *)
                print "Found unkonwn Siemens terminal adapter"
                ;;
        esac
        ;;
    *WAVECOM*)
        TA_VENDOR=WAVECOM
        print "Found Wavecom GPRS terminal adapter"
        ;;

    *)
        print "Found unkonwn terminal adapter"
        ;;
esac


##############################################################################
# Check and enter PIN
##############################################################################

#2009-08-07 gc: Wavecom only sends result code, no "OK"
at_cmd "AT+CPIN?" 10 "+CPIN:"|| error
wait_quiet 1
case $r in
    *SIM?PIN*)
        if [ -z "$GPRS_PIN" ]; then
            print "ERROR: The GPRS_PIN env variable is not set"
            exit 1
        fi
        print "sending pin"
        at_cmd "AT+CPIN=$GPRS_PIN" 30 || error
        # Wait until registered
        if [ $TA_VENDOR == "WAVECOM" ]; then
            sleep 20
        else
            sleep 10
        fi
        ;;
    
    *READY* | *SIM?PUK*)
        ;;
    
    *)
        error
        ;;
esac
print "SIM ready"

##############################################################################
# Select (manually) GSM operator
##############################################################################
op_cmd="AT+COPS=0"

if [ ! -z "$GPRS_OPERATOR" ]; then
    op_cmd="AT+COPS=1,2,\"$GPRS_OPERATOR\""
    print "Setting manual selected operator to $op_cmd"
fi

if [ ! -z "$GPRS_NET_ACCESS_TYPE" ]; then
    op_cmd="$op_cmd,$GPRS_NET_ACCESS_TYPE"
fi

at_cmd $op_cmd || error


##############################################################################
# Wait for registration
##############################################################################
loops=0
network=""
while [ $loops -lt 120 ]
do
    at_cmd "AT+CREG?" 2
    case $r in
        *CREG:?0,1*)
            network="home"
            break
            ;;
        
        *CREG:?0,5*)
            network="roaming"
            break
            ;;

        *CREG:*)
            network="not registered"
            ;;
    esac
done

if [ -z "$network" ]; then
    print "No response from terminal adapter on AT+CREG?"

# wavecom modem sometimes don't respond on AT +CREG?
    if [ $TA_VENDOR != "WAVECOM" ]; then
        error
    fi
fi

if [ $network == "no registered" ]; then
  print "Failed to register"
  error
fi

# reset operator format to alphanumeric 16 characters
at_cmd "AT+COPS=3,0"
at_cmd "AT+COPS?"

print "res: $r"
r=${r#*\"}
r=${r%\"*}

print "Registered on $network network: $r"

##############################################################################
# send user init string
##############################################################################
 
if [ ! -z "$GPRS_INIT" ]; then
    at_cmd $GPRS_INIT
    print "Result user init: $r"
fi


##############################################################################
# query some status information from terminal adapter
##############################################################################
  print "querying status information from terminal adapater:\n"
#
  at_cmd "ATi"
  print "Terminal Adapter: $r"
#
  at_cmd "AT+CGSN"
  print "IMEI: $r"
#
  at_cmd "AT+CIMI"
  print "IMSI: $r"
#
  at_cmd "AT+CSQ"
  print "Signal Quality: $r"

  if [ $TA_VENDOR == "SIEMENS" ]; then
#
      at_cmd "AT^SCID"
      print "SIM card id: $r"
#
      at_cmd "AT^MONI"
      print "^MONI: $r"
#
      at_cmd "AT^MONP"
      print "^MONP: $r"

      wait_quiet 5

  fi



##############################################################################
# attach PDP context to GPRS 
##############################################################################

if [ -z "$GPRS_APN" ]; then
    print "The GPRS_APN env variable is not set"
    exit 1
fi

# entering APN may take longer time if network is busy
print "Entering APN: $GPRS_APN"
at_cmd "AT+CGDCONT=1,\"IP\",\"$GPRS_APN\"" 60

case $? in
    0)
        print "Successfully entered APN"
        ;;
    
    1)
        print "ERROR entering APN"
        error
        ;;

    *)
        print "TIMEOUT entering APN"
        error
        ;;
esac

at_cmd "AT+CGACT?"
print "PDP Context attach: $r"
wait_quiet 1

#GPRS_CMD_SET=1
if [ ! -z "$GPRS_CMD_SET" ]; then
    at_cmd "AT+GMI"
    # activate PDP context
    at_cmd "AT+CGACT=1,1" 90 || error
    at_cmd "" 2

    #enter data state
    case $TA_VENDOR in
        WAVECOM)
            at_cmd "AT+CGDATA=1" 90 "CONNECT" || error
            ;;
        SIEMENS | *)
            at_cmd "AT+CGDATA=\"PPP\",1" 90 "CONNECT" || error
            ;;
    esac

    # 2009-08-07 gc: AT+CGDATA dosn't deliver DNS addresses on Siemens! BUG?
else
    at_cmd "AT D*99***1#" 90 "CONNECT" || error
fi

ppp_args="call gprs_comgt nolog nodetach $GPRS_PPP_OPTIONS"
if [ ! -z "$GPRS_USER" ]; then
    ppp_args="$ppp_args user $GPRS_USER"
fi

print "running pppd: /usr/sbin/pppd $ppp_args"
/usr/sbin/pppd $ppp_args <&3 >&3 &
# save pppd's PID file in case of pppd hangs before it writes the PID file
echo $! >/var/run/ppp0.pid
wait
print "pppd terminated"
#fuser -k $GPRS_DEVICE
exit 0
