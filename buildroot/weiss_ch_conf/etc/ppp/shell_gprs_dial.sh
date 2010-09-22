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

echo $0 [Version 2010-09-22 15:44:10 gc]

#GPRS_DEVICE=/dev/ttyS0
#GPRS_DEVICE=/dev/com1
#GPRS_BAUDRATE=115200
#. /etc/default/gprs
#GPRS_DEVICE=/dev/com1

GPRS_STATUS_FILE=/tmp/gprs-stat
echo -n >$GPRS_STATUS_FILE

GRPS_ERROR_COUNT_FILE=/tmp/gprs-error


# echo file descriptor to raw AT commands and received answer from
# terminal adapter
# if comment out, no echo of AT command chat
AT_VERBOSE_FD=1

cr=`echo -n -e "\r"`


##############################################################################
# Shell functions
##############################################################################

set_gprs_led() {
    echo 0 "$*" >/tmp/gprs_led
}

SYS_MESG=/usr/weiss/bin/sys-mesg
sys_mesg() {
    test -x $SYS_MESG && $SYS_MESG -n GPRS "$@"

}
# internationalization functions for messages (identity)
N_() {
  echo "$@"
}

M_() {
  echo "$@"
}

sys_mesg_net() {
    test -x $SYS_MESG && $SYS_MESG -n GPRS_NET "$@"

}


sys_mesg_remove() {
    test -x $SYS_MESG && $SYS_MESG -n GPRS -r
}


# extract part of string by regular expression
re_extract() {
   awk "/$1/ {print gensub(/.*$1.*/,\"\\\\1\",1)}"                              
}                                                                               

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
    if [ \! -z "$AT_VERBOSE_FD" ]; then
        # hide PIN-Number from log, substitute with <hidden>
        echo >&$AT_VERBOSE_FD "${*/+CPIN=????/+CPIN=<hidden>}"
    fi
}

print_rcv() {
      # echo removes leading / trailing whitespaces
      if ! [ -z "`echo -n $1`" ]; then
          print_at_cmd "RCV: $1"
      fi
}

error() {
# not supported by most TAs
#    at_cmd "AT+CERR"
#    print "Extended error report: $r"

    exit 1
}

reset_terminal_adapter() {
    print "Reseting terminal adapter"
    if [ \! -z "$GPRS_RESET_CMD" ]; then
        /bin/sh -c "$GPRS_RESET_CMD"
        sleep 20
    else
        case $TA_VENDOR in
            WAVECOM)
                at_cmd "AT+CFUN=1"
                sleep 60
                ;;

            SIEMENS | Cinterion )
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
  local wait_str=""
  if [ "$1" -gt 0 ]; then wait_time=$1; fi
  if [ \! -z "$2" ]; then wait_str="$2"; fi

  local line=""
  while IFS="" read -r -t$wait_time line<&3
  do
      #remove trailing carriage return
      line=${line%%${cr}*}
      print_rcv "$line"

      if [ \! -z "$wait_str" ]; then
#          print "wq: str -${wait_str}-"
          case $line in
              *"${wait_str}"*)
#                  print_at_cmd "got wait: $wait_str"
                  return 1
                  ;;

              *)
                  ;;
          esac
#      else 
#          print "wq: no str"
      fi
  done
  return 0
}


# execute AT cmd and wait for "OK"
# Params: 1 AT Command String
#         2 Wait time in seconds (default 10)
#         3 Additional WAIT string
# Result $r Result string
line_break=" "
at_cmd() {
  # r is returned to caller
  r=""
  local wait_time=2
  local count=0
  local wait_str="OK"
  local echo_rcv=""

  if [ "$2" -gt 0 ]; then wait_time=$2; fi
  if [ \! -z "$3" ]; then wait_str="$3"; fi

  wait_quiet 1

  print_at_cmd "SND: $1"
  echo -e "$1\r" >&3 &

  while true
  do
      local line=""
      if ! IFS="" read -r -t$wait_time line <&3
      then
          sys_mesg -e TA_AT -p warning `M_ "AT command timeout" `
          print timeout
          return 2
      fi
      #remove trailing carriage return
      line="${line%%${cr}*}"
      print_rcv "$line"
      #suppress echo of AT command in result string
      if [ -z "$echo_rcv" -a "$line" = "$1" ]; then echo_rcv="x"; continue; fi
      if [ -z "$r" ]; then
	r="$line"
      else
        r="$r$line_break$line"
      fi
      case $line in
          *OK*)
              return 0
              ;;
          *"${wait_str}"*)
#              print_at_cmd "got wait: $wait_str"
              return 0
              ;;

          *ERROR*)
              return 1
              ;;
      esac
      count=$(($count+1))
      if [ $count -gt 15 ]
      then
          sys_mesg -e TA_AT -p warning `M_ "AT command timeout" `
          print timeout
          return 2
      fi
  done

  if [ -d /proc/$! ]; then echo TTY driver hangs; return 3; fi
  return 0
}


# sendsms phonenum "text"
sendsms() {
    wait_quiet 1
    send "AT+CMGS=\"$1\""
    wait_quiet 20 "AT+CMGS="
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
# load modules and detect ttyUSB* devices
##############################################################################
find_usb_device() {
    local reload_modules=$1
    local vendor=$2
    local product=$3
    local dev_app=$4
    local dev_mod=$5

    if [ \! -z "$reload_modules" ]; then
        sleep 1
        rmmod usbserial; modprobe usbserial vendor=0x$vendor product=0x$product
        sleep 1
    fi

    for l in 1 2 3 4 5
    do
        if [ -c "$dev_app" ]; then
            # Application port
            GPRS_DEVICE_APP="$dev_app"
            GPRS_DEVICE=$GPRS_DEVICE_APP
            if [ \! -z "$dev_mod" -a -c "$dev_mod" ]; then
                # Modem Port
                GPRS_DEVICE_MODEM="$dev_mod"
            fi
            break
        fi
        sleep 2
    done

    # force module reload if no device is found!
    if [ -z "$GPRS_DEVICE_APP" ]; then
        rmmod usbserial; modprobe usbserial vendor=0x$vendor product=0x$product
        sleep 1
        for l in 1 2 3 4 5
        do
            if [ -c "$dev_app" ]; then
            # Application port
                GPRS_DEVICE_APP="$dev_app"
                GPRS_DEVICE=$GPRS_DEVICE_APP
                if [  \! -z "$dev_mod" -a -c "$dev_mod" ]; then
                # Modem Port
                    GPRS_DEVICE_MODEM="$dev_mod"
                fi
                break
            fi
            sleep 2
        done
    fi
}

print_usb_device() {
    echo "found $1"
    status GPRS_DEVICE_USB "$1"
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
                local d=
                print_usb_device "Huawei Technologies Co., Ltd. E220 HSDPA Modem"
                if [ \! -z "$reload_modules" ]; then
                    mount -tusbfs none /proc/bus/usb
                    /usr/bin/huaweiAktBbo
                fi

                find_usb_device "$reload_modules" 12d1 1003 /dev/ttyUSB0
                ;;

        0681:0041)
                print_usb_device "Siemens HC25 in USB mass storage mode"

                sleep 1

                for scsi in /sys/bus/scsi/devices/*
                do
                    #echo check: $scsi: `cat $scsi/model`
                    case `cat $scsi/model` in
                        *HC25\ flash\ disk*)
                            #echo path: "$scsi/block:"*
                            local x=`readlink $scsi/block\:*`
                            local dev=${x##*/}
                            if [ \! -z "$dev" ]; then
                                echo "ejecting Siemens HC25 in USB mass storage device: /dev/$dev"
                                eject "/dev/$dev"
                                exit 1
                            fi
                            ;;
                    esac
                done
                ;;

            0681:0040)
                print_usb_device "Siemens HC25 in USB component mode"

                find_usb_device "$reload_modules" 0681 0040 /dev/ttyUSB0 /dev/ttyUSB2
                ;;


            0681:0047)
                print_usb_device "Siemens HC25 in USB CDC-ACM mode"

                find_usb_device "$reload_modules" 0681 0047 /dev/ttyUSB0 /dev/ttyACM0
                ;;

            114f:1234)
                print_usb_device "Wavecom Fastrack Extend FXT003 CDC-ACM Modem"
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
        *Cinterion* )
            TA_VENDOR=Cinterion
            case $r in
                *MC35*)
                    TA_MODEL=MC35
                    print "Found Cinterion MC35 GPRS terminal adapter"
                    ;;
                *MC52*)
                    TA_MODEL=MC52
                    print "Found Cinterion MC52 GPRS terminal adapter"
                    ;;
                *MC55*)
                    TA_MODEL=MC55
                    print "Found Cinterion MC55 GPRS terminal adapter"
                    ;;
                *HC25*)
                    TA_MODEL=HC25
                    print "Found Cinterion HC25 UMTS/GPRS terminal adapter"
                # HC25: enable network (UTMS=blue/GSM=green) status LEDs
                    at_cmd "AT^sled=1"
                    ;;
                *)
                    print "Found unkonwn Cinterion terminal adapter"
                    ;;
            esac
            ;;
        *SIEMENS* )
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
            # Query WAVECOM reset timer for log
            at_cmd "AT+WRST?"
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


initiazlize_port() {
    local device=$1

    # prevent blocking when opening the TTY device due modem status lines
    if ! stty -F $device $GPRS_BAUDRATE clocal -crtscts -brkint -icrnl -imaxbel -opost -onlcr -isig -icanon -echo -echoe -echok -echoctl -echoke 2>&1 ; then

    # stty may say "no such device"
        print "stty failed"
        return 1
    fi

    echo -n AT${cr} >$device &
    sleep 5
    if [ -d /proc/$! ]; then
        echo TTY driver hangs;
        return 1
    fi



    return 0
}


##############################################################################
# handle RING
##############################################################################
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
                eval "$GPRS_ANSWER_CSD_CMD" &
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

# get_break_count() {
#     k=${status##*brk:}
#     if [ "$k" == "$status" ]; then
#         b=0
#     else
#         b=${k%% *}
#     fi
# #    print "brk: $b"
# }


##############################################################################
# check and handle SMS
##############################################################################
# 2009-08-28 gc: experimental, on ring
check_and_handle_SMS() {
    # List UNREAD SMS
    local line=""
    local sms_ping=""
    local sms_reboot=""
    local sms_reconnect=""

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

            *"weisselectronic ping"*)
                sms_ping=$SMS_NUM
                ;;

            *"weisselectronic reconnect"*)
                sms_reconnect=$SMS_NUM
                ;;

            *"weisselectronic reboot"*)
                sms_reboot=$SMS_NUM
                ;;

            *)
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
        # no reconnect
        return 0
    fi

    if [ \! -z "$sms_reconnect" ]; then
        sendsms $sms_reconnect "rc `hostname`: CSQ: $GPRS_CSQ `uptime`"
        return 1
    fi

    if [ \! -z "$sms_reboot" ]; then
        logger -t GPRS got reboot request per SMS
        sleep 10
        reboot
    fi
    return 1
}

##############################################################################
# Main
##############################################################################
set_gprs_led off

if [ \! -z "$GPRS_START_CMD" ]; then
    /bin/sh -c "$GPRS_START_CMD"
fi


##############################################################################
# check error count
##############################################################################
GPRS_ERROR_COUNT_MAX=5
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
print "(Modem device: $GPRS_DEVICE_MODEM)"

status GPRS_DEVICE_CMD   "$GPRS_DEVICE"
status GPRS_DEVICE_MODEM "$GPRS_DEVICE_MODEM"

if ! initiazlize_port $GPRS_DEVICE; then
    sleep 10
    killall watchdog
    reboot
    exit 3
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

if [ $GPRS_ERROR_COUNT -ge $GPRS_ERROR_COUNT_MAX ] ; then
    print max err count reached
    # reload drivers in case /dev/ttyUSBxx device is not present
    init_and_load_drivers 1
    GPRS_ERROR_COUNT=0
    identify_terminal_adapter
    reset_terminal_adapter
    init_and_load_drivers 1
fi

cat >$GRPS_ERROR_COUNT_FILE <<FILE_END
# GRPS-Error Count, do not edit!
GPRS_ERROR_COUNT=$GPRS_ERROR_COUNT
FILE_END

if ! at_cmd "AT"; then
    sys_mesg -e TA -p error `M_ "No response from terminal adapter, check connection" `
    exit 1
fi
print "Terminal adapter responses on AT command"
sys_mesg -e TA -p `M_ "No error" `
# blink on pulse of 50ms for each 1000ms
set_gprs_led 1000 50


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
# Set verbose error reporting
##############################################################################
at_cmd "AT+CMEE=2"


##############################################################################
# Check and enter PIN
##############################################################################

#2009-08-07 gc: Wavecom only sends result code, no "OK"
if ! at_cmd "AT+CPIN?" 10 "+CPIN:"; then
    print result: $r
    err_msg=`echo $r | re_extract '\+CME ERROR: (.*)'`
    if [ \! -z "$err_msg" ]; then err_msg=": $err_msg"; fi
    sys_mesg -e SIM -p error `M_ "SIM card error" `
    # not translated message with embedded error message string
    sys_mesg -e NET -p error "SIM card error message: ${err_msg}"
    error
fi
wait_quiet 1

case $r in
    *'SIM PIN'*)
        if [ -z "$GPRS_PIN" ]; then
            sys_mesg -e SIM -p error `M_ "SIM card requires PIN" `
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

    *READY*)
        ;;

    *'SIM PUK'*)
        sys_mesg -e SIM -p error `M_ "SIM card requires PUK" `
        exit 1
        ;;

    *)
        error
        ;;
esac
print "SIM ready"
sys_mesg -e SIM -p `M_ "No error" `

##############################################################################
# Select (manually) GSM operator
##############################################################################

op_cmd="AT+COPS=0"

case "$TA_VENDOR $TA_MODEL" in
    *SIEMENS*HC25* | *Cinterion*HC25* )
        # supply net access type (GSM or UMTS) for Siemens HC25 UMTS TA
        if [ \! -z "$GPRS_NET_ACCESS_TYPE" ]; then
            op_cmd="AT+COPS=0,,,$GPRS_NET_ACCESS_TYPE"
        fi


        if [ \! -z "$GPRS_OPERATOR" -a "$GPRS_OPERATOR" -ne 0 ]; then
            if [ \! -z "$GPRS_NET_ACCESS_TYPE" ]; then
                op_cmd="AT+COPS=1,2,\"$GPRS_OPERATOR\",$GPRS_NET_ACCESS_TYPE"
            else
                op_cmd="AT+COPS=1,2,\"$GPRS_OPERATOR\""
            fi
            print "Setting manual selected operator to $op_cmd"
        fi
        ;;

    *)
        if [ \! -z "$GPRS_OPERATOR" -a "$GPRS_OPERATOR" -ne 0 ]; then
            op_cmd="AT+COPS=1,2,\"$GPRS_OPERATOR\""
            print "Setting manual selected operator to $op_cmd"
        fi
        ;;
esac



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
            sys_mesg -e NET -p error `M_ "Failed to register on GSM/UMTS network" `
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
sys_mesg -e NET -p `M_ "No error" `

status GPRS_NETWORK $r
# blink two pulses of 50ms for each 1000ms
set_gprs_led 1000 50 100 50

##############################################################################
# send user init string
##############################################################################

if [ \! -z "$GPRS_INIT" ]; then
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
  if [ $GPRS_CSQ -lt 10 ]; then
      sys_mesg_net -e NET -p warning `M_ "Low GSM/UMTS Signal Quality" `
  else
      sys_mesg_net -e NET -p `M_ "No error" `
  fi
  status GPRS_CSQ $GPRS_CSQ

  case $TA_VENDOR in
      SIEMENS | *Cinterion* )

          case "$TA_MODEL" in
              *HC25*)
                  ;;
              
              *)
                  at_cmd "AT^SCID"
                  print "SIM card id: $r"
                  r=${r##*SCID: }
                  status GPRS_SCID "${r%% OK}"
                  ;;
          esac
#
	  line_break="<br>"
          at_cmd "AT^MONI"
          status GPRS_MONI "${r%%<br>OK}"
#
          at_cmd "AT^MONP"
          status GPRS_MONP "${r%%<br>OK}"
          
          case "$TA_MODEL" in
              *HC25*)
                  ;;
              
              *)
                  at_cmd "AT^SMONG"
                  status GPRS_SMONG "${r%%<br>OK}"
                  ;;
          esac

  	  line_break=" "
          wait_quiet 5
          ;;

      WAVECOM)
          # query cell environment description 
          # @todo the output must be reformated
          # 2010-09-10 gc: dosn't work properly
          #at_cmd "AT+CCED=0,16" 60
          #status GPRS_CCED "${r%% OK}"
          ;;

  esac

# read on phone number
case "$TA_VENDOR $TA_MODEL" in
    *SIEMENS*MC35*)
        at_cmd 'AT+CPBS="ON" +CPBR=1,4'
# +CPBR: 1,"+491752928173",145,"Eigene Rufnummer"  OK
        cnum=`echo $r | re_extract '\+CPBR: [0-9]+,"(\+?[0-9]+)",.*'`
        ;;

    *)
        at_cmd "AT+CNUM"
# +CNUM: "Eigene Rufnummer","+491752928173",145 OK
        cnum=`echo $r | re_extract '\+CNUM: "[^"]*","(\+?[0-9]+)",[.0-9]+.*'`
        ;;
esac

print "Own number: $r, num: $cnum"
status GPRS_NUM ${cnum}





##############################################################################
# SMS initialization
##############################################################################
# switch SMS to TEXT mode
at_cmd "AT+CMGF=1"

#2009-08-28 gc: enable URC on incoming SMS (and break of data/GPRS connection)
case "$TA_VENDOR $TA_MODEL" in
    *SIEMENS*HC25* | *Cinterion*HC25*)
        at_cmd "AT+CNMI=2,1"
        ;;
    *WAVECOM*)
        at_cmd "AT+CNMI=2,1"
        # enable Ring Indicator Line on
        #   Bit 1: Incoming calls (RING)
        #   Bit 2: Incoming SMS (URCs: +CMTI; +CMT)
        at_cmd "AT+WRIM=1,$(((1<<2)+(1<<1))),33"
        ;;
    *)
        at_cmd "AT+CNMI=3,1"
        ;;
esac

do_restart=16

while [ $do_restart -ne 0 ]
do
    print "do_restart: $do_restart"
    do_restart=$(($do_restart-1))

    if ! wait_quiet 5 "RING"; then
        on_ring
    fi

    check_and_handle_SMS

##############################################################################
# attach PDP context to GPRS
##############################################################################

    if [ -z "$GPRS_APN" ]; then
        print "The GPRS_APN env variable is not set"
        sys_mesg -e APN -p error `M_ "The GPRS_APN env variable is not set" `
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

    if [ \! -z "$GPRS_DEVICE_MODEM" ]; then
# use a separate modem device for PPP connection,
# AT command interpreter on application port remains still accessible
# connect file handle 3 with modem device
        print "Switching to modem interface $GPRS_DEVICE_MODEM"
        if  initiazlize_port $GPRS_DEVICE_MODEM; then

            exec 3<>$GPRS_DEVICE_MODEM
            for l in 1 2 3 4 5
            do
                if at_cmd "AT"; then
                    break
                fi
            done
        else
            GPRS_DEVICE_MODEM=""
        fi
    fi

    if [ \! -z "$GPRS_CMD_SET" ]; then
        at_cmd "AT+GMI"
    # activate PDP context
        at_cmd "AT+CGACT=1,1" 90 || error
        at_cmd "" 2

    #enter data state
        case $TA_VENDOR in
            WAVECOM)
                at_cmd "AT+CGDATA=1" 90 "CONNECT" || error
                ;;
            SIEMENS | Cinterion | *)
                at_cmd "AT+CGDATA=\"PPP\",1" 90 "CONNECT" || error
                ;;
        esac

    # 2009-08-07 gc: AT+CGDATA dosn't deliver DNS addresses on Siemens! BUG?
    else
        at_cmd "AT D*99***1#" 90 "CONNECT" || error
    fi

#sleep 1
    ppp_args="call gprs_comgt nolog nodetach $GPRS_PPP_OPTIONS"
    if [ \! -z "$GPRS_USER" ]; then
        ppp_args="$ppp_args user $GPRS_USER"
    fi
    if [ \! -z "$GPRS_PASSWD" ]; then
        print "running pppd: /usr/sbin/pppd ${ppp_args} password <hidden>"
        ppp_args="$ppp_args password $GPRS_PASSWD"
    else
        print "running pppd: /usr/sbin/pppd ${ppp_args}"
    fi
    stty -F $GPRS_DEVICE -ignbrk brkint
    /usr/sbin/pppd $ppp_args <&3 >&3 &
# save pppd's PID file in case of pppd hangs before it writes the PID file
    ppp_pid=$!
    echo $ppp_pid >/var/run/ppp0.pid

    set -x

    if [ \! -z "$GPRS_DEVICE_MODEM" ]; then
# reconnect file handle 3 on application interface
        print "Switching to application interface $GPRS_DEVICE"
        exec 3<>$GPRS_DEVICE
        for l in 1 2 3 4 5
        do
            if at_cmd "AT"; then
                break
            fi
        done
    fi

    case "$TA_VENDOR $TA_MODEL" in
    # *SIEMENS*MC*)
    #     case $GPRS_DEVICE in
    #         /dev/com1 | /dev/ttyAT1)

    #             status=`cat /proc/tty/driver/atmel_serial | grep 1:;`
    #             get_break_count
    #             break_count=$b

    #             while [ -d /proc/$ppp_pid ]
    #             do
    #                 status=`cat /proc/tty/driver/atmel_serial | grep 1:;`
    # #example:
    # # 1: uart:ATMEL_SERIAL mmio:0xFFFC4000 irq:7 tx:14820 rx:18025 oe:1 RTS|CTS|DTR|DSR|CD

    # #check if RI is set in status line
    #                 if [ "${status##*|RI}" != "$status" ]; then
    #                     echo ringing
    #                     if [ \! -z "$GPRS_ANSWER_CSD_CMD" ] ; then
    #                         on_ring
    #                     fi
    #                 fi

    #                 get_break_count
    #                 if [ "$b" -ne "$break_count" ]; then
    #                     echo BREAK received
    #                     kill $ppp_pid
    #                     break_count=$b
    #                 fi

    #                 sleep 1
    #             done
    #             ;;

    #         *)
    #             # reading status while connected is currently only
    #             # supported on /dev/com1
    #             wait
    #             ;;
    #     esac
    #     ;;

        *SIEMENS*HC25*)
            if [ \! -z "$GPRS_DEVICE_MODEM" ]; then
                count=360
                while [ -d /proc/$ppp_pid ]
                do
                    # answer on ^SQPORT should be "Application" not "Modem"!
                    # at_cmd "AT^SQPORT"
                    count=$(($count+1))
                    if [ $count -gt 360 ]
                    then
                        count=0
                        #
                        # query Packet Switched Data Information:
                        at_cmd 'AT^SIND="psinfo",2'
                        case "$r" in
                            *'^SIND: psinfo,0,0'*)
                                print "PSINFO: no (E)GPRS available in current cell"
                                ;;
                            *'^SIND: psinfo,0,1'*)
                                print "PSINFO: GPRS available"
                                ;;
                            *'^SIND: psinfo,0,2'*)
                                print "PSINFO: GPRS attached"
                                ;;
                            *'^SIND: psinfo,0,3'*)
                                print "PSINFO: EGPRS available"
                                ;;
                            *'^SIND: psinfo,0,4'*)
                                print "PSINFO: EGPRS attached"
                                ;;
                            *'^SIND: psinfo,0,5'*)
                                print "PSINFO: camped on WCDMA cell"
                                ;;
                            *'^SIND: psinfo,0,6'*)
                                print "PSINFO: WCDMA PS attached"
                                ;;
                            *'^SIND: psinfo,0,7'*)
                                print "PSINFO: camped on HSDPA-capable cell"
                                ;;
                            *'^SIND: psinfo,0,8'*)
                                print "PSINFO: PS attached in HSDPA-capable cell"
                                ;;
                        esac
                    fi
                   #

                    while [ -d /proc/$ppp_pid ]  && IFS="" read -r -t10 line<&3
                    do
                        line=${line%%${cr}*}
                        print_rcv "APP_PORT: $line"
                        case $line in
                            *+CMTI:* | *+CMT:*)
                                echo SMS URC received
                                if ! check_and_handle_SMS; then
                                    kill -TERM $ppp_pid
                                fi
                                ;;

                            *RING*)
                                print "ringing"
                                on_ring
                                break;
                                ;;
                        esac
                    done
                    sleep 1
                done
            fi
            # wait till pppd process has terminated
            wait
            ;;

#    *WAVECOM*)
        *)
            print "waiting for modem status change"
            /usr/bin/modemstatus-wait ri break pid $ppp_pid <&3
            case $? in
                1)
                # RING
                    echo got RING
                    kill -TERM $ppp_pid
                    ;;

                2)
                # BREAK
                    echo BREAK received
                    kill -TERM $ppp_pid
                    ;;

                64)
                # PROCESS PID Terminated
                    do_restart=0
                    ;;

                *)
                # error
                    # modemstatus-wait fails on TIOCGICOUNT ioctrl on devices
                    # not supporting it (for instance ttyACM)
                    # so we wait here for pppd's termination

                    #kill -TERM $ppp_pid
                    #do_restart=0
                    ;;
            esac

            # wait till pppd process has terminated
            wait
            ;;
    esac

    command_mode
done

print "$0 terminated"
exit 0



# Local Variables:
# mode: shell-script
# time-stamp-pattern: "20/\\[Version[\t ]+%%\\]"
# backup-inhibited: t
# End:
