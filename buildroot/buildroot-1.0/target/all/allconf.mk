#*****************************************************************************
#* 
#*  @file          allconf.mk
#*
#*  Set all changed configuration files for root filesystem images for Weiss CCM2200
#*
#*  @version       1.0 (\$Revision: 1818 $)
#*  @author        Markus Forster <br>
#*                 Weiss-Electronic GmbH
#* 
#*  $LastChangedBy: fom9tr $  
#*  $Date: 2006-05-31 $
#*  $URL:  $
#*
#*  @par Modification History:
#*    2006-05-31 mf: initial version (unixdef)
#*
#*  
#*****************************************************************************
#	host-fakeroot makedevs $(STAGING_DIR)/fakeroot.env mtd-host

#TARGET_REF = $(TARGET_DIR)_ref

.PHONY: allconf
allconf:
	-@rm -rf *.jffs2
	-rm $(STAGING_DIR)/fakeroot.env
	-touch $(STAGING_DIR)/fakeroot.env
	#-@cp -a $(TARGET_DIR) $(TARGET_REF)
	-@sh ./rootchange_create.sh
	-@tar -xvf root_changes.tar -C $(TARGET_DIR)
	-@rm root_changes.tar
	# remove dropbear from automatic start at boottime
	# dropbear is replaced by openSSH
	-@find $(TARGET_DIR) -type f -perm +111 | xargs $(STRIP) 2>/dev/null || true;
	@chmod 0600 $(TARGET_DIR)/etc/ssh_host*
	@rm -rf $(TARGET_DIR)/usr/man
	@rm -rf $(TARGET_DIR)/usr/share/man
	@rm -rf $(TARGET_DIR)/usr/info
#############################################################
#
# Toplevel Makefile options
#
#############################################################
TARGETS += allconf


