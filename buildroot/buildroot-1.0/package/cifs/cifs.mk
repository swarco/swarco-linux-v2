#############################################################
#
# CIFS
#
#############################################################

CIFS_MOUNT_REVISION=6103

# Don't alter below this line unless you (think) you know
# what you are doing! Danger, Danger!

CIFS_SITE=http://websvn.samba.org/cgi-bin/viewcvs.cgi/*checkout*/branches/SAMBA_3_0/source/client
CIFS_MOUNT_SOURCE=$(CIFS_SITE)/mount.cifs.c?rev=$(CIFS_MOUNT_REVISION)
CIFS_DIR=$(BUILD_DIR)/cifs
CIFS_DLDIR=$(DL_DIR)/cifs
CIFS_TARGET_BINARY:=/sbin/mount.cifs


$(CIFS_DIR) $(CIFS_DLDIR):
	mkdir -p $@

$(CIFS_DLDIR)/.downloaded: $(CIFS_DLDIR)
	$(WGET) -P $(CIFS_DLDIR) -O $(CIFS_DLDIR)/mount.cifs.c $(CIFS_MOUNT_SOURCE)
	touch $@

$(CIFS_DIR)/.unpacked:	$(CIFS_DLDIR)/.downloaded $(CIFS_DIR)
	cp -a $(CIFS_DLDIR)/*.c $(CIFS_DIR)/
	touch $@


$(CIFS_DIR)/mount.cifs:	$(CIFS_DIR)/mount.cifs.c
	$(TARGET_CC) -O2 -o $@ $<


$(TARGET_DIR)/$(CIFS_TARGET_BINARY): $(CIFS_DIR)/mount.cifs 
	/usr/bin/install -c $(CIFS_DIR)/mount.cifs $(TARGET_DIR)/sbin
	$(STRIP) $@


cifs:	uclibc $(TARGET_DIR)/$(CIFS_TARGET_BINARY)

cifs-source: $(CIFS_DIR)/.unpacked 

cifs-clean:
	rm -f $(TARGET_DIR)/$(CIFS_TARGET_BINARY)
	rm -f $(CIFS_DIR)/mount.cifs $(CIFS_DIR)/mount.cifs.o

cifs-dirclean:
	rm -rf $(CIFS_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(strip $(BR2_PACKAGE_CIFS)),y)
TARGETS+=cifs
endif
