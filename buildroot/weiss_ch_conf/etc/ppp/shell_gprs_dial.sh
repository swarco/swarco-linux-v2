#!/bin/sh
#*****************************************************************************/
#* 
#*  @file          shell_gprs_dial.sh
#*
#*  Shell script based GPRS/UMTS dial script
#*
#*  @version       0.1
#*  @date          
#*  @author        Guido Classen
#* 
#*  Changes:
#*    2009-08-28 gc: initial version
#*  
#****************************************************************************/

echo $0 [Version 2009-10-20 18:42:16 gc]

#GPRS_DEVICE=/dev/ttyS0
#GPRS_DEVICE=/dev/com1
#GPRS_BAUDRATE=115200
#. /etc/default/gprs
#GPRS_DEVICE=/dev/com1

GPRS_STATUS_FILE=/tmp/gprs-stat
GRPS_ERROR_COUNT_FILE=/tmp/gprs-error


# echo file descriptor to raw AT commands and received answer from
# terminal adapter
# if comment out, no echo of AT command chat
AT_VERBOSE_FD=1

cr=`echo -n -e "\r"`


##############################################################################
# Shell functions
##############################################################################

# print log message
print() {
    echo "$*"
}

status() {
    local var=$1
    shift
    echo >>$GPRS_STATUS_FILE $var=\'"$*"\'
}

print_at_cmd()
{
    if [ ! -z "$AT_VERBOSE_FD" ]; then echo >&$AT_VERBOSE_FD "$*"; fi
}

print_rcv() {
      # echo removes leading / trailing whitespaces
      if ! [ -z "`echo -n $1`" ]; then
          print_at_cmd "RCV: $1"
      fi
}

error() {
    at_cmd "AT+CERR"
    print "Extended error report: $r" 

    exit 1
}

reset_terminal_adapter() {
    print "Reseting terminal adapter"
    if [ ! -z "$GPRS_RESET_CMD" ]; then
        /bin/sh -c "$GPRS_RESET_CMD"
        sleep 20
    else
        case $TA_VENDOR in
            WAVECOM)
                at_cmd "AT+CFUN=1"
                sleep 60
                ;;

            SIEMENS)
                at_cmd "AT+CFUN=1,1"
                sleep 60
                ;;

            *)
                print "Don't known how to reset terminal adapter $TA_VENDOR"
                #try Siemens command
                at_cmd "AT+CFUN=1,1"
                sleep 60
                ;;
        esac
    fi
}

send() {
  print_at_cmd "SND: $1"
  echo -e "$1\r" >&3 &
}

command_mode() {
  sleep 2
  print_at_cmd "SND: +++ (command mode)"
  # IMPORTEND: To enter command mode +++ is followed by a delay of 1000ms
  #            There must not follow a line feed character after +++
  #            so use -n option!
  echo -ne "+++">&3&
  sleep 2
}


wait_quiet() {
#  print "wait_quiet $1"
  local wait_time=2
  if [ "$1" -gt 0 ]; then wait_time=$1; fi

  local line=""
  while IFS="" read -r -t$wait_time line<&3
  do
      #remove trailing carriage return
      line=${line%%${cr}*}
      print_rcv "$line"
  done
  return 0
}


# execute AT cmd and wait for "OK"
# Params: 1 AT Command String
#         2 Wait time in seconds (default 10)
#         3 Additional WAIT string
# Result $r Result string
at_cmd() {
  # r is returned to caller
  r=""
  local wait_time=2
  local count=0
  local wait_str="OK"
  local echo_rcv=""

  if [ "$2" -gt 0 ]; then wait_time=$2; fi
  if [ ! -z "$3" ]; then wait_str="$3"; fi

  wait_quiet 1

  print_at_cmd "SND: $1"
  echo -e "$1\r" >&3 &

  while true
  do
      local line=""
      if ! IFS="" read -r -t$wait_time line<&3
      then
          print timeout
          return 2
      fi    
      #remove trailing carriage return
      line="${line%%${cr}*}"
      print_rcv "$line"
      #suppress echo of AT command in result string
      if [ -z "$echo_rcv" -a "$line" = "$1" ]; then echo_rcv="x"; continue; fi
      r="$r $line"
      case $line in
          *OK*)
              return 0
              ;;
          *${wait_str}*)
              print_at_cmd "got wait: $wait_str"
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


# sendsms phonenum "text"
sendsms() {
    send "AT+CMGS=\"$1\"" 
    sleep 3
    send "$2\\032"

    while true
    do
        local line=""
        IFS="" read -r -t5 line<&3 || break;
        
        #remove trailing carriage return
        line=${line%%${cr}*}
        print_rcv "$line"
        case $line in
            *OK* )
                print sending SMS sucessfully
                return 0;
                ;;
            
            *ERROR*)
                print ERROR sending SMS
                return 1
                break;
                ;;
        esac
    done
    
    return 1        
}

##############################################################################
# Driver loading and initialisation of special (USB) devices
##############################################################################
init_and_load_drivers() {
    local reload_modules=$1

    for id in /sys/bus/usb/devices/*
    do
        case `cat $id/idVendor`:`cat $id/idProduct` in
            :)
                continue
                ;;
        
        12d1:1003)
                echo "found Huawei Technologies Co., Ltd. E220 HSDPA Modem"
                if [ \! -z "$reload_modules" ]; then
                    mount -tusbfs none /proc/bus/usb
                    /usr/bin/huaweiAktBbo 
                    
                    sleep 1
                    rmmod usbserial; modprobe usbserial vendor=0x12d1 product=0x1003
                fi
                for l in 1 2 3 4 5 
                do
                    if [ -c /dev/ttyUSB0 ]; then 
                        GPRS_DEVICE=/dev/ttyUSB0
                        break
                    fi
                    sleep 2
                done
                ;;
        
        0681:0041)
                echo "found Siemens HC25 in USB mass storage mode"
                
                sleep 1
                
                for scsi in /sys/bus/scsi/devices/*
                do
                    echo check: $scsi: `cat $scsi/model`
                    case `cat $scsi/model` in
                        *HC25\ flash\ disk*)
                    #echo path: "$scsi/block:"*
                            local x=`readlink $scsi/block\:*`
                            local dev=${x##*/}
                            if [ ! -z "$dev" ]; then
                                echo ejecting /dev/$dev
                                eject /dev/$dev
                                exit 1
                            fi
                            ;;
                    esac
                done
                ;;
                
            0681:0040)
                echo "found Siemens HC25 in USB component mode"

                if [ \! -z "$reload_modules" ]; then
                    sleep 1
                    rmmod usbserial; modprobe usbserial vendor=0x0681 product=0x0040
                    sleep 1
                fi
                
                for l in 1 2 3 4 5 
                do
                    if [ -c /dev/ttyUSB0 ]; then 
                    # Modem Port
                        GPRS_DEVICE=/dev/ttyUSB0
                    # Application port
                        GPRS_DEVICE_SECOND=/dev/ttyUSB2
                        break
                    fi
                    sleep 2
                done
                ;;
            
        
            0681:0047)
                echo "found Siemens HC25 in USB CDC-ACM mode"
                
                if [ \! -z "$reload_modules" ]; then
                    sleep 1
        # activate second application port (/dev/ttyUSB0)
                    rmmod usbserial; modprobe usbserial vendor=0x0681 product=0x0047
                    sleep 1
                fi
                
                for l in 1 2 3 4 5 
                do
                    if [ -c /dev/ttyACM0 ]; then 
                # Modem Port
                        GPRS_DEVICE=/dev/ttyACM0
                # Application port
                        GPRS_DEVICE_SECOND=/dev/ttyUSB0
                        break
                    fi
                    sleep 2
                done
                ;;
            esac
    done
}

##############################################################################
# Check vendor / model of connected terminal adapter
##############################################################################
identify_terminal_adapter() {
    at_cmd "ATi" || return 1
    print "Terminal adpater identification: $r"
    
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
        
        *huawei*)
            TA_VENDOR=HUAWEI
            case $r in
                *E17X*)
                    TA_MODEL=E17X
                    print "Found Huawei E17X terminal adapter"
                    ;;
                *)
                    print "Found unkonwn Huawei terminal adapter"
                    ;;
            esac
            ;;
        
        *)
            print "Found unkonwn terminal adapter"
            ;;
    esac
}



##############################################################################
# Main
##############################################################################

if [ ! -z "$GPRS_START_CMD" ]; then
    /bin/sh -c "$GPRS_START_CMD"
fi


##############################################################################
# check error count
##############################################################################
if [ -f $GRPS_ERROR_COUNT_FILE ] ; then
    . $GRPS_ERROR_COUNT_FILE
    GPRS_ERROR_COUNT=$(($GPRS_ERROR_COUNT + 1))
    init_and_load_drivers
else
    init_and_load_drivers 1
    GPRS_ERROR_COUNT=0
fi



##############################################################################
# Check if TTY device does not block after open 
##############################################################################
if [ ! -c $GPRS_DEVICE ]; then
 exit 1
fi

print "Starting GPRS connection on device $GPRS_DEVICE ($GPRS_BAUDRATE baud)"

# prevent blocking when opening the TTY device due modem status lines
stty -F $GPRS_DEVICE clocal -crtscts

echo . <$GPRS_DEVICE >/dev/null&
sleep 5
if [ -d /proc/$! ]; then 
    echo TTY driver hangs; 
    sleep 10
    reboot
    exit 3; 
fi


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

#command_mode

for l in 1 2 3 4 5 
do
    if at_cmd "AT"; then
        break
    else
        command_mode
        wait_quiet 1
    fi
done

##############################################################################
# check error count
##############################################################################

print GPRS_ERROR_COUNT: $GPRS_ERROR_COUNT
        
if [ $GPRS_ERROR_COUNT -gt 5 ] ; then
    print max err count reached
    GPRS_ERROR_COUNT=0
    identify_terminal_adapter
    reset_terminal_adapter
    init_and_load_drivers 1
fi

cat >$GRPS_ERROR_COUNT_FILE <<FILE_END
# GRPS-Error Count, do not edit!
GPRS_ERROR_COUNT=$GPRS_ERROR_COUNT
FILE_END

at_cmd "AT" || exit 1
print "Terminal adapter responses on AT command"

echo -n >$GPRS_STATUS_FILE
status GPRS_CONNECT_TIME `date "+%Y-%m-%d %H:%M:%S"`


# 2009-08-28 gc: hang up if there is a connection in background
# 2009-09-16 gc: ATH may block for longer time on bad reception conditions
#                =>Timeout 20
if ! at_cmd "ATH" 20; then
    # when ATH hangs, any character is used to abort command and is
    # not interpreted by terminal adapter
    at_cmd "AT"
    wait_quiet 5
fi


identify_terminal_adapter


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
# Set verbose error reporting
##############################################################################
at_cmd "AT+CMEE=2" 

##############################################################################
# Select (manually) GSM operator
##############################################################################
op_cmd="AT+COPS=0"

if [ \! -z "$GPRS_OPERATOR" -a "$GPRS_OPERATOR" -ne 0 ]; then
    op_cmd="AT+COPS=1,2,\"$GPRS_OPERATOR\""
    print "Setting manual selected operator to $op_cmd"
fi

if [ ! -z "$GPRS_NET_ACCESS_TYPE" ]; then
    op_cmd="$op_cmd,$GPRS_NET_ACCESS_TYPE"
fi

at_cmd $op_cmd 90 || error


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
    loops=$(($loops+1))
done

if [ -z "$network" ]; then
    print "No response from terminal adapter on AT+CREG?"

# wavecom modem sometimes don't respond on AT +CREG?
    if [ $TA_VENDOR != "WAVECOM" ]; then
        error
    fi
fi

status GPRS_ROAMING $network

if [ "$network" == "not registered" ]; then
  print "Failed to register on network"
  error
fi

# reset operator format to alphanumeric 16 characters
at_cmd "AT+COPS=3,0"
at_cmd "AT+COPS?"

print "res: $r"
r=${r#*\"}
r=${r%\"*}

print "Registered on $network network: $r"

status GPRS_NETWORK $r

##############################################################################
# send user init string
##############################################################################
 
if [ ! -z "$GPRS_INIT" ]; then
    at_cmd $GPRS_INIT
    print "Result user init: $r"
fi


##############################################################################
# Data/CSD initialization
##############################################################################
# single numbering scheme: all incoming calls without "bearer
# capability" as DATA
at_cmd "AT+CSNS=4"
at_cmd "ATS0=0"

##############################################################################
# query some status information from terminal adapter
##############################################################################
  print "querying status information from terminal adapater:"
#
  at_cmd "ATi"
  print "Terminal Adapter: ${r%% OK}"
  status GPRS_TA "${r%% OK}"
#
  at_cmd "AT+CGSN"
  print "IMEI: ${r%% OK}"
  status GPRS_IMEI ${r%% OK}
#
  at_cmd "AT+CIMI"
  print "IMSI: ${r%% OK}"
  status GPRS_IMSI ${r%% OK}
#
  at_cmd "AT+CSQ"
  print "Signal Quality: ${r%% OK}"
  r=${r##*CSQ: }
  GPRS_CSQ=${r%%,*}
  status GPRS_CSQ $GPRS_CSQ

  if [ $TA_VENDOR == "SIEMENS" ]; then
#
      at_cmd "AT^SCID"
      print "SIM card id: $r"
      r=${r##*SCID: }
      status GPRS_SCID "${r%% OK}"
#
      at_cmd "AT^MONI"
      status GPRS_MONI "${r%% OK}"
#
      at_cmd "AT^MONP"
      status GPRS_MONP "${r%% OK}"

      at_cmd "AT^SMONG"
      status GPRS_SMONG "${r%% OK}"

      wait_quiet 5

  fi

# read on phone number
case "$TA_VENDOR $TA_MODEL" in
    *SIEMENS*MC35*)
        at_cmd 'AT+CPBS="ON" +CPBR=1,4'
        ;;
    
    *)
        at_cmd "AT+CNUM"
        ;;
esac
status GPRS_NUM ${r%% OK}
#print "Own number: $r"



##############################################################################
# SMS initialization
##############################################################################
# switch SMS to TEXT mode
at_cmd "AT+CMGF=1"

#2009-08-28 gc: enable URC on incoming SMS (and break of data/GPRS connection)
at_cmd "AT+CNMI=3,1"

# List UNREAD SMS
local line=""
local sms_ping=""
local sms_reboot=""

send 'AT+CMGL="REC UNREAD"'
while IFS="" read -r -t5 line<&3
do
     line=${line%%${cr}*}
      print_rcv "$line"
      case $line in
          *OK*)
              break
              ;;
          *+CMGL:*)
              #extract SMS phone number
              SMS_NUM=${line##*\"REC UNREAD\",\"}
              SMS_NUM=${SMS_NUM%%\"*}
              print got phone $SMS_NUM
              ;;

          *weisselectronic\ ping*)
              sms_ping=$SMS_NUM
              ;;

          *weisselectronic\ reboot*)
              sms_reboot=$SMS_NUM
              ;;
      esac
done

# delete all RECEIVED READ SMS from message store
# fails with "+CMS ERROR: unknown error" if no RECEIVED READ SMS available
# => IGNORE Error
at_cmd "AT+CMGD=0,1"
wait_quiet 1

if [ \! -z "$sms_ping" ]; then
    sendsms $sms_ping "`hostname`: CSQ: $GPRS_CSQ `uptime`"
fi

if [ \! -z "$sms_reboot" ]; then
    logger -t GPRS got reboot request per SMS
    sleep 10
    reboot
fi


##############################################################################
# attach PDP context to GPRS 
##############################################################################

if [ -z "$GPRS_APN" ]; then
    print "The GPRS_APN env variable is not set"
    exit 1
fi

print "Entering APN: $GPRS_APN"
at_cmd "AT+CGDCONT=1,\"IP\",\"$GPRS_APN\"" 240

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

#sleep 1
ppp_args="call gprs_comgt nolog nodetach $GPRS_PPP_OPTIONS"
if [ ! -z "$GPRS_USER" ]; then
    ppp_args="$ppp_args user $GPRS_USER"
fi

print "running pppd: /usr/sbin/pppd $ppp_args"
stty -F $GPRS_DEVICE -ignbrk brkint
/usr/sbin/pppd $ppp_args <&3 >&3 &
# save pppd's PID file in case of pppd hangs before it writes the PID file
echo $! >/var/run/ppp0.pid

# 2009-08-28 gc: experimental, on ring
on_ring() {
    local count=0;
    kill $ppp_pid
    while [ -d /proc/$ppp_pid ]
    do
        sleep 1
    done
    print "waiting for ring"
    command_mode

    while IFS="" read -r -t120 line<&3
    do
        line=${line%%${cr}*}
        print_rcv "$line"
        case $line in
            *RING*)

                at_cmd "ATA" 90 "CONNECT" || return 1
                echo starting $GPRS_ANSWER_CSD_CMD
                /bin/sh -c "$GPRS_ANSWER_CSD_CMD" &
                rsm_pid=$!
                while [ -d /proc/$rsm_pid ]
                do
                    
                    status=`cat /proc/tty/driver/atmel_serial | grep 1:;`
    #example:
    # 1: uart:ATMEL_SERIAL mmio:0xFFFC4000 irq:7 tx:14820 rx:18025 oe:1 RTS|CTS|DTR|DSR|CD
                    
    #check if RI is set in status line
                    if [ "${status##*|CD}" == "$status" ]; then
                        echo CD lost
                        kill $rsm_pid
                        return 0;
                    fi
                done
                
                break;
              ;;

      esac

      count=$(($count+1))
      if [ $count -gt 15 ]
      then
          print timeout
          return 2
      fi

    done

}

get_break_count() {
    k=${status##*brk:}
    if [ "$k" == "$status" ]; then
        b=0
    else
        b=${k%% *}
    fi
#    print "brk: $b"
}

case $GPRS_DEVICE in
    /dev/com1 | /dev/ttyAT1)
        
        ppp_pid=$!
        
        
        status=`cat /proc/tty/driver/atmel_serial | grep 1:;`
        get_break_count
        break_count=$b
        
        while [ -d /proc/$ppp_pid ]
        do
            status=`cat /proc/tty/driver/atmel_serial | grep 1:;`
    #example:
    # 1: uart:ATMEL_SERIAL mmio:0xFFFC4000 irq:7 tx:14820 rx:18025 oe:1 RTS|CTS|DTR|DSR|CD
            
    #check if RI is set in status line
            if [ "${status##*|RI}" != "$status" ]; then
                echo RINGING
                if [ \! -z "$GPRS_ANSWER_CSD_CMD" ] ; then
                    on_ring
                fi
            fi

            get_break_count
            if [ "$b" -ne "$break_count" ]; then
                echo BREAK received
                kill $ppp_pid
                break_count=$b
            fi
            
            sleep 1
        done

        ;;

    *)
        wait
        ;;
esac

print "pppd terminated"
#fuser -k $GPRS_DEVICE
exit 0



# Local Variables:
# mode: shell-script
# time-stamp-pattern: "20/\\[Version[\t ]+%%\\]"
# backup-inhibited: t
# End:
