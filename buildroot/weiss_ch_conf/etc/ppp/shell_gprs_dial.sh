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

echo $0 [Version 2009-09-07 10:44:56 gc]

#GPRS_DEVICE=/dev/ttyS0
#GPRS_DEVICE=/dev/com1
#GPRS_BAUDRATE=115200
#. /etc/default/gprs
#GPRS_DEVICE=/dev/com1

# echo file descriptor to raw AT commands and received answer from
# terminal adapter
# if comment out, no echo of AT command chat
AT_VERBOSE_FD=1

cr=`echo -n -e "\r"`



# print log message
print() {
    echo $*
}

print_at_cmd()
{
    if [ ! -z "$AT_VERBOSE_FD" ]; then echo >&$AT_VERBOSE_FD $*; fi
}

error() {
    at_cmd "AT+CERR"
    print "Extended error report: $r" 

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
  print "wait_quiet $1"
  local wait_time=2
  if [ "$1" -gt 0 ]; then wait_time=$1; fi

  local line=""
  while read -r -t$wait_time line<&3
  do
      #remove trailing carriage return
      line=${line%%${cr}*}
      print_at_cmd "RCV: $line"
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
  local wait_str="OK"
  local echo_rcv=""

  if [ "$2" -gt 0 ]; then wait_time=$2; fi
  if [ ! -z "$3" ]; then wait_str="$3"; fi

  print_at_cmd "SND: $1"
  echo -e "$1\r" >&3 &

#  sleep $wait_time
  
  while true
  do
      local line=""
      if ! read -r -t$wait_time line<&3
      then
          print timeout
          return 2
      fi    
      #remove trailing carriage return
      line=${line%%${cr}*}
      print_at_cmd "RCV: $line"
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

##############################################################################
# Driver loading and initialisation of special (USB) devices
##############################################################################
for id in /sys/bus/usb/devices/*
do
    if [ -z `cat $id/idVendor` -o  -z `cat $id/idProduct` ]; then
        continue;
    fi

#    echo checking: id `cat $id/idVendor` idprod: `cat $id/idProduct`

    if [ `cat $id/idVendor` = "12d1" -a `cat $id/idProduct` = "1003" ]; then
        echo "found Huawei Technologies Co., Ltd. E220 HSDPA Modem"
        mount -tusbfs none /proc/bus/usb
        /usr/bin/huaweiAktBbo 

        sleep 1
        rmmod usbserial; modprobe usbserial vendor=0x12d1 product=0x1003
        for l in 1 2 3 4 5 
        do
            if [ -c /dev/ttyUSB0 ]; then break; fi
            sleep 2
        done
    fi

    if [ `cat $id/idVendor` = "0681" -a `cat $id/idProduct` = "0041" ]; then
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
    fi
    
    if [ `cat $id/idVendor` = "0681" -a `cat $id/idProduct` = "0040" ]; then
        echo "found Siemens HC25 in USB component mode"
        
        sleep 1
        
        rmmod usbserial; modprobe usbserial vendor=0x0681 product=0x0040
        
        sleep 1
        
        for l in 1 2 3 4 5 
        do
            if [ -c /dev/ttyUSB0 ]; then 
                GPRS_DEVICE=/dev/ttyUSB0
                break
            fi
            sleep 2
        done
    fi
    
done


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
        print okay
        break
    else
        command_mode
    fi

    if [ $l == "5" ]; then
        error
    fi
done

print "Terminal adapter responses on AT command"


# 2009-08-28 gc: hang up if there is a connection in background
at_cmd "ATH"

##############################################################################
# Check vendor / model of connected terminal adapter
##############################################################################

at_cmd "ATi" || error
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
# Data/CSD initialization
##############################################################################
# single numbering scheme: all incoming calls without "bearer
# capability" as DATA
at_cmd "AT+CSNS=4"
at_cmd "ATS0=0"

##############################################################################
# SMS initialization
##############################################################################

# read on phone number
#at_cmd "AT+CNUM"
#print "Own number: $r"

# switch SMS to TEXT mode
at_cmd "AT+CMGF=1"

#2009-08-28 gc: enable URC on incoming SMS (and break of data/GPRS connection)
at_cmd "AT+CNMI=3,1"

# List UNREAD SMS
local line=""
send 'AT+CMGL="REC UNREAD"'
while read -r -t5 line<&3
do
     line=${line%%${cr}*}
      print_at_cmd "RCV: $line"
      case $line in
          *OK*)
              break
              ;;

          *weisselectronic\ reboot*)
              logger -t GPRS got reboot request per SMS
              sleep 10
              reboot
              ;;
      esac
done

#print "SMS: $r"
#wait_quiet 10

# delete all RECEIVED READ SMS from message store
at_cmd "AT+CMGD=0,1"



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

    while read -r -t120 line<&3
    do
        line=${line%%${cr}*}
        print_at_cmd "RCV: $line"
        case $line in
            *RING*)

                at_cmd "ATA" 90 "CONNECT" || return 1
                echo starting remote_subnet_mgr
                /usr/weiss/bin/remote_subnet_mgr /etc/weiss/sm1/rem_subnet_prm &
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
                # enable if needed
                on_ring
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
# End:
