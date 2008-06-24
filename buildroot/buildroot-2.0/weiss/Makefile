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


.PHONY: weiss_prepare_root
weiss_prepare_root: overwrite_target_device_table install_chconf
	echo gc:hello weiss_prepare_root
