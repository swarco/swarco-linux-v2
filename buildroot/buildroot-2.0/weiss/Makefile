#*****************************************************************************
#* 
#*  @file          Makefile
#*
#*                 buildroot basesystem 2.0 weiss package directory
#*
#*  @par Program:  Weiss-Embedded-Linux / Buildroot
#*
#*  @version       1.0 (\$Revision: 332 $)
#*  @author        Guido Classen
#*                 Weiss Electronic GmbH
#* 
#*  $LastChangedBy: clg9tr $  
#*  $Date:  $
#*  $URL: svn://server-i/layer-79/makefile $
#*
#*  @par Modification History:
#*   2008-06-24 gc: initial version
#*
#*****************************************************************************


include weiss/package/*/*.mk

TARGETS+=weiss_prepare_root


$(PROJECT_BUILD_DIR)/device_table.txt: target/device/Atmel/root/device_table.txt weiss/device_table_ext.txt
	cat $? >$@

.PHONY: overwrite_target_device_table
overwrite_target_device_table: $(PROJECT_BUILD_DIR)/device_table.txt
	$(eval TARGET_DEVICE_TABLE:=$(PROJECT_BUILD_DIR)/device_table.txt)


.PHONY: install_chconf
install_chconf: 
	echo install_chconf: 
	(cd weiss/ch_conf; tar cf - --exclude .svn .) | (cd $(TARGET_DIR);tar xvf -)
	-mv $(TARGET_DIR)/etc/init.d/S*ntp $(TARGET_DIR)/etc/init.d/not_started
	# create links from /var to /tmp
	for dir in lock log pcmcia run spool tmp; \
	do \
	  rm -rf $(TARGET_DIR)/var/$$dir; \
	  ln -sf /tmp $(TARGET_DIR)/var/$$dir; \
	done
	-rm $(TARGET_DIR)/etc/resolv.conf
	ln -sf /proc/mounts $(TARGET_DIR)/etc/mtab
	ln -sf /tmp/resolv.conf $(TARGET_DIR)/etc/resolv.conf
	# 2009-02-04 gc: buildroot now installs sftp-server in
	#                /usr/lib/sftp-server again
	# buildroot installs "sftp-server" subsystem in /usr/sbin, we
	# expect it in /usr/lib
	#-rm $(TARGET_DIR)/usr/lib/sftp-server
	#ln -sf ../sbin/sftp-server $(TARGET_DIR)/usr/lib/sftp-server
	echo "Welcome to Weiss-Electronic GmbH Embedded Linux v2.0 " ` date '+#%Y-%m-%d#' `  > $(TARGET_DIR)/etc/issue

.PHONY: weiss_prepare_root
weiss_prepare_root: overwrite_target_device_table install_chconf
