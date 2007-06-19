#!/bin/sh
#*****************************************************************************
#* 
#*  @file          ccm_configurator.sh
#*
#*                 CCM2200 Konfigurationsmenü
#*                 2006 Weiss-Electronic GmbH
#*
#*  @version       0.1.0
#*  @date          <2006-05-03 mf>
#*  @author        Markus Forster
#* 
#*  @par change history:
#*     2006-05-03 mf: initial version 
#*  
#*****************************************************************************

# file for selection of menu-items
selection=/tmp/ccm_config_selection.tmp
# start parameter for dialog
dialog="dialog --cr-wrap"
# name for main title
backtitle="\
CCM2200 Configurator"

menu_instructions="\
Menu selection with cursor keys <Enter>
Highlited keys are hotkeys.  
<Esc><Esc> to quit"
#, <?> f�r Hilfe.

file_selection_help="\
File selection
TAB / cursor left/right field selection
Cursor up/down file selection
<Space>+/ to confirm selection
<Return> Select marked File"

nand_flash=/dev/mtdblock/3

config_files_for_archive="
        etc/hosts
	etc/network/interfaces
	etc/hostname
	etc/passwd
	etc/shadow
        mnt/install
"

if [ "$EDITOR"="" ]; then
    if [ -f /bin/nano ]; then
	EDITOR=nano
    else
	EDITOR=vi
    fi
fi

separator()
{
    echo \
"*************************************************************************"
}

do_menu()
{
    item_count=$(($#/2))
    $dialog --title "$menu_title"          \
	--backtitle "$backtitle"           \
	--menu "$menu_instructions"        \
	$((10+$item_count)) 75 $item_count \
	"$@" 2>$selection
    result=$?
    item=`cat <$selection`
    if [ $result -eq 0 ]; then
	selected_item=$item
	result=0;
    fi

    [ -e $selection ] && rm $selection
    return $result
}

do_checklist()
{
    item_count=$((($#-1)/3))
    retvar?"$1"
    shift
    $dialog --title "$checklist_title"        \
	--backtitle "$backtitle"              \
	--checklist "$checklist_instructions" \
	16 76 $item_count                     \
	"$@" 2>$selection
    result=$?
    item=`cat <$selection`
    eval $retvar=""
    
    if [ $result -eq 0 ]; then
	eval $retvar="\$item"
	result=0;
    fi

    [ -e $selection ] && rm $selection
    return $result
}

do_input_generic()
{
    $dialog --title "$input_title"                    \
	--backtitle "$backtitle"                      \
        $dialog_function "$2" 10 75 "$3" 2>$selection 
    result=$?
    item=`cat <$selection`
    
    if [ $result -eq 0 ] ; then
        eval $1='"$item"'
        result=0;
    fi

    [ -e $selection ] && rm $selection
    return $result
}


do_input()
{
    dialog_function="--inputbox"
    do_input_generic "$@"
}


do_input_password()
{
    dialog_function="--passwordbox"
    do_input_generic "$@"
}

do_message_box()
{
    $dialog --backtitle "$backtitle" --msgbox "$1" 16 68
    return $?
}

do_existing_file_selection()
{
    item="/"
    while true
      do
      $dialog --help-button --backtitle "$backtitle"     \
	  --begin 2 1 --fselect $item 11 78 2>$selection
      result=$?
      item="`cat <$selection`"
      
      case $result in
	  0)
	      if [ -f "$item" ]; then
		  eval $1="\\$item"
		  [ -e $selection ] && rm $selection
		  return 0;
	      fi
	      ;;
	  2)
	      do_message_box "$file_selection_help"
	      ;;
	  *)
	      [ -e $selection ] && rm $selection
	      return 1;
	      ;;
      esac
    done
}

do_new_file_selection()
{
    item="/"
    while true
      do
      $dialog --help-button --backtitle "$backtitle"    \
	  --begin 2 1 --fselect $item 11 78 2>$selection
      result=$?
      item="`cat <$selection`"
      
      case $result in
	  0)
	      if ! [ -d "$item" ]; then
		  eval $1="\\$item"
		  [ -e $selection ] && rm $selection
		  return 0;
	      fi
	      ;;
	  2)
	      do_message_box "$file_selection_help"
	      ;;
	  *)
	      [ -e $selection ] && rm $selection
	      return 1;
	      ;;
      esac
    done
}

do_mount_readwrite()
{
    for mount_pt in $remount_selection
      do
      echo Remounting $mount_pt readwrite
      eval mount -o remount,rw $mount_pt
    done
}

do_mount_readonly()
{
    for mount_pt in $remount_selection
      do
      echo Remounting $mount_pt readonly
      eval mount -o remount,ro $mount_pt
    done
}

migrate_rootfs_and_update()
{
    if ! do_message_box "\
CAUTION: You are about to delete the root partition of a running system and overwriting it with a new and unconfigured one.\n
Ctrl-C to abbord!"
    then
	exit0
    fi
    /etc/init.d/S45weissuz stop >/dev/null 2>&1
    /etc/init.d/S90goahead stop >/dev/null 2>&1
    killall S42bluetooth
    killall rfcomm
    killall hcid
    killall sdpd
    killall getty
    if ! do_message_box "\
    System is performing the requested update operation. All processes are killed! in this step! \n  An active ssh connection will be closed, but the operation will continue. \n
After the update is finished, the system will reboot.\n
Ctrl-C to abbord"
	then
	exit 0
    fi
    ledloop & >/dev/null 2>&1
    mkdir -p /tmp/new_root
    mount -tramfs none /tmp/new_root/
    cp -a /etc /sbin /bin /usr/bin /usr/sbin /lib /usr/lib /tmp/new_root >/dev/null 2>&1

    for dir in old_root proc dev var root
      do
        mkdir -p /tmp/new_root/$dir
    done

    for dir in .ssh bin
      do
      cp -a /root/$dir /tmp/new_root/root
    done
    
    mount -tproc none /tmp/new_root/proc
    mount -tdevfs none /tmp/new_root/dev
    OUTPUT_DEV=dev/console
    if [ -c /$OUTPUT_DEV ] &&
	stty -F /$OUTPUT_DEV cooked &&
	stty -F /$OUTPUT_DEV -nl
    then
	echo $OUTPUT_DEV gefunden
	echo "Copying image" > /$OUTPUT_DEV
    else
	echo "no VGA console available"
	OUTPUT_DEV=dev/null
    fi
    cd /tmp/new_root
    pivot_root . old_root
    cd /
    exec chroot . nohup sh -c "
      umount /old_root/proc;
      fuser -mv /old_root/;
      fuser -mk9 /old_root/; 
      fuser -mv /old_root/;
      echo step1;
      mount -oremount,ro /old_root;
      echo NAND device will be erased ....;
      mtd_debug erase /dev/mtd/5 0 33554432;
      echo \"Transfering $1 to NAND device ...\"; 
      nandwrite -j /dev/mtd/5 \"/old_root$1\";
      sync;
      sleep 5;
      echo Rebooting...;
      exec reboot;
      "
}

backup_rootfs()
{
    /etc/init.d/S45weissuz stop >/dev/null 2>&1
    /etc/init.d/S90goahead stop >/dev/null 2>&1
    killall S42bluetooth
    killall rfcomm
    killall hcid
    killall sdpd
    killall getty
    ledloop & >/dev/null 2>&1
    mkdir -p /tmp/new_root
    mount -tramfs none /tmp/new_root/
    cp -a /etc /sbin /bin /usr/bin /usr/sbin /lib /usr/lib /tmp/new_root >/dev/null 2>&1

    for dir in old_root proc dev var root
      do
        mkdir -p /tmp/new_root/$dir
    done

    for dir in .ssh bin
      do
      cp -a /root/$dir /tmp/new_root/root
    done
    
    mount -tproc none /tmp/new_root/proc
    mount -tdevfs none /tmp/new_root/dev
    OUTPUT_DEV=dev/console
    if [ -c /$OUTPUT_DEV ] &&
	stty -F /$OUTPUT_DEV cooked &&
	stty -F /$OUTPUT_DEV -nl
    then
	echo $OUTPUT_DEV gefunden
	echo "Copying image" > /$OUTPUT_DEV
    else
	echo "no VGA console available"
	OUTPUT_DEV=dev/null
    fi
    cd /tmp/new_root
    pivot_root . old_root
    cd /
    exec chroot . nohup sh -c "
      umount /old_root/proc;
      fuser -mv /old_root/;
      fuser -mk9 /old_root/; 
      fuser -mv /old_root/;
      echo step1;
      mount -oremount,ro /old_root;
      mount -oremount,rw /old_root;
      mount -oremount,rw /old_root/mnt/cifs;
      mtd_debug read /dev/mtd/5 0 134217728 \"/old_root$1\"; 
      sync;
      sleep 5;
      echo Rebooting...;
      exec reboot;
      "
}

install_image()
{
    migrate_rootfs_and_update "$1" "$2"
}
	

copy_file_with_gauge()
{
    microperl -e '

print "0\n";

open(IN_FILE, "<$ARGV[0]") or die "Error opening $ARGV[0]";
open(OUT_FILE, ">$ARGV[1]") or die "Error opening $ARGV[1]";
#geht nicht???
#sysopen(IN_FILE, $ARGV[0], O_RDONLY) or die "Error opening $ARGV[0]";
#sysopen(OUT_FILE, $ARGV[1], O_WRONLY | O_TRUNC | O_CREAT) or die "Error opening $ARGV[1]";


my $filesize = -s $ARGV[0];
my $buffer;
my $length;
my $totallength=0;
my $oldpercent=0;

if ($filesize == 0 || -b $ARGV[0]) {
  # get length of block device with lssek
  $filesize = sysseek(IN_FILE,0,2);
  sysseek(IN_FILE,0,0);
}
$|=1; #enable autoflush
while (($length = sysread(IN_FILE, $buffer, 4096)) > 0) {
    if ($filesize > 0) {
        my $percent = sprintf "%d", $totallength * 100.0 / $filesize;
        if ($percent != $oldpercent) {
            print "$percent\n";
            $oldpercent=$percent;
        }
    }
    die "IO-Error" if (syswrite(OUT_FILE, $buffer, $length) != $length);
    $totallength+=$length;
}
print "100\n";
close IN_FILE;
close OUT_FILE;

' $1 $2 |     $dialog --title "$gauge_title"    \
        --backtitle "$backtitle"                \
        --gauge "kopiere $1 nach $2" 16 68


}

dump_file()
{
    if [ -x /usr/bin/microperl ]; then
	copy_file_with_gauge "$1" "$2"
    else
	dd if="$1" of="$2"
    fi
 }

ifconfig_get()
{
    awk_value="$2"
    export awk_value
    ifconfig $1 | awk '
    BEGIN{
	ip_regexp="[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+";
    }
    {
	if (match($0, ENVIRON["awk_value"])) {
		ip=substr($0, RSTART+RLENGTH);
		if (match(ip, ip_regexp)) {
			print substr(ip, RSTART, RLENGTH);
                }
        }
    }'
}

ifconfig_get_alias()
{
    base_interface=${2%%:[0-9]}
    value=`ifconfig_get $interface "$3"`
    if [ -z "$value" ]; then
	value=`ifconfig_get $base_interface "$3"`
    fi
    eval $1=\\$value
}

wait_for_return()
{
    echo
    
    separator
    echo
    if [ $1 -eq 0 ]; then
	echo erfolgreich!
    else
	echo Fehler aufgetreten!
    fi
    echo Bitte Return für weiter
    echo
    separator
    read
}

default_value()
{
    eval test -z \$$1 && eval $1="$2"
}

do_kill_process()
{
    tokill=`ps| grep $1| grep -v grep| awk '{print $1;}'`
    kill ${tokill}
}

static_ip_settings()
{
    interface=eth0
    input_title="Network address for $interface"

    ifconfig_get_alias ip_address $interface "addr:"
    ifconfig_get_alias net_mask   $interface "Mask:"
    gateway=`route | awk '/default/ {print $2}'`

    do_input ip_address "IP-Address" $ip_address
    do_input net_mask "Network-Mask" $net_mask
    do_input gateway "Default-Gateway" $gateway

    remount_selection="/"
    
      ifconfig $interface $ip_address netmask $net_mask
      route del default
      route add default gateway $gateway dev $interface
      do_mount_readwrite
      echo "\
        auto $interface                
        iface $interface inet static   
        address $ip_address            
        netmask $net_mask              
        gateway $gateway               
      " > /etc/network/interfaces
      do_mount_readonly
}

main_ip_settings()
{
  interface=eht0
  menu_title="Network address setup"
  do_menu                           \
  "dynamic"    "dynamic IP via DHCP" \
  "static"     "static IP address"   \
  "admin-mode" "zeroconf IP4ALL"
  if [ "$selected_item" = "static" ]
  then
    do_kill_process zeroconf
    eval "static_ip_settings"
  else
    if [ "$selected_item" = "admin-mode" ]
    then
      zeroconf -i eth0
    else
      do_mount_readwrite
      echo "\
        auto $interface             
        iface $interface inet dhcp
      " > /etc/network/interfaces
      do_mount_readonly
      do_kill_process zeroconf
      udhcp -b -i $interface -n -p /tmp/udhcp.$interface.pid
      #/etc/init.d/S40network restart
    fi
  fi 
}

main_hostname()
{
    hostname=CCM2200-1
    remount_selection="/"
    input_title="System hostname"
    do_input hostname "Hostname" $hostname
    hostname "$hostname"
    do_mount_readwrite
    echo $hostname > /etc/hostname
    do_mount_readonly
}

main_reboot()
{
    if ! [ "$USER" = "root" ]
    then
	do_message_box "Error:\n  You have to be root to do that!" 
    else
        reboot
    fi
}

check_module()
{
    lsmod | grep ${1##*/} || insmod /lib/modules/`uname -r`/$1.ko
}

main_mount_fs()
{
    menu_title="Select protocol"
    if do_menu \
	"cifs" "CIFS (Windows)" \
	"nfs"  "NFS (Unix)"     \
	"usb"  "USB device"
	then
	case $selected_item in
	    cifs)
		modprobe cifs
		if do_input mount_pt "mountpoint" /mnt/cifs &&
		    do_input smb_share "Directory name f.g. //hostname/directory" "//" &&
		    do_input smb_user "User name e.g. weiss-adr\\xxx9tr" "" &&
		    do_input_password smb_passwd "Password" ""
		    then
		    check_module kernel/fs/cifs/cifs

		    unmount $mount_pt >/dev/null 2>&1
		    echo
		    separator

		    mount -oremount,rw /
		    mount.cifs          \
			"$smb_share" "$mount_pt" \
		    -o ro,username="$smb_user",password="$smb_passwd"
		    result=$?
		    if ! [ -h /etc/mtab ]; then
			rm /etc/mtab
			ln -s /proc/mounts /etc/mtab
		    fi
		    mount -oremount,ro /

		    wait_for_return $result
		fi
		;;
	    nfs)
		if
		    do_input mount_pt "mountpoint" /mnt/nfs &&
		    do_input nfs_name "NFS name" 192.168.42.1:/mnt/weiss/ccm2200
		    then
		    check_module kernel/net/sunrpc/sunrpc
		    check_module kernel/fs/lockd/lockd
		    check_module kernel/fs/nfs/nfs
		    if [ -f /bin/portmap ]; then
			ps -A | grep portmap | grep -v grep || (portmap &)
		    fi
		    umount $mount_pt >/dev/null 2>&1
		    echo
		    separator
		    mount -t nfs -o soft,nolock,async,timeo=14,rsize=1024,wsize=1024 "$nfs_name" "$mount_pt"
		    result=$?
		    echo
		    wait_for_return $result
		fi
		;;
	    usb)
		if
		    do_input mount_pt "mountpoint" /mnt/usb &&
		    do_input usb_device "USB device" /dev/scsi/host0/bus0/target0/lun0/part1
		    then
		    umount $mount_pt >/dev/null 2>&1
		    echo
		    separator
		    mount -t vfat "$usb_device" "$mount_pt"
		    result=$?
		    echo
		    wait_for_return $result
		fi
		;;
	esac
    fi
}

main_install_software()
{
    menu_title="Install Software/configuration"
    if do_menu                       \
	"Image" "System image setup" \
	"weiss-apps" "Weiss applications" \
	"backup" "Backup root image" \
	#"Configuration" "Configuration setup"
	then
	case $selected_item in
	    Image)
		if do_existing_file_selection filename; then
		    umount $nand_flash
		    install_image "$filename" $nand_flash
		    mount $nand_flash
		fi
		;;
	    weiss-apps)
		if do_existing_file_selection filename; then
		    remount_selection="/"
		    do_mount_readwrite
		    tar xvzf "$filename" -C /
		    do_mount_readonly
		fi
		;;
	    backup)
		if do_new_file_selection filename; then
		    backup_rootfs "$filename"
		fi
		;;
	    esac
    fi
}

main_backup()
{
    if do_new_file_selection filename; then
	#umount_flash_disk
	dump_file /dev/mtdblock/5 "$filename"
	#mount_flash_disk
    fi
}

while menu_title="Main configuration";   \
    do_menu                              \
    "ip_settings" "Network addresses"               \
    "hostname"    "System's network name"     \
    "reboot"      "Restart system"            \
    "mount_fs"    "Mount a Network share."           \
    "install_software" "Install new software" \
    "backup"      "Backup"
  do
  eval "main_${selected_item}"
done
