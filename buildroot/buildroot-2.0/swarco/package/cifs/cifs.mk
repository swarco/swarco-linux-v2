##############################################################################
#
# mount.cifs
#
##############################################################################
CIFS_VER:=6103
CIFS_SOURCE:=mount.cifs.c

CIFS_URL:='http://viewcvs.samba.org/cgi-bin/viewcvs.cgi/*checkout*/branches/SAMBA_3_0/source/client/mount.cifs.c?rev=17605'
CIFS_DIR:=$(BUILD_DIR)/cifs
CIFS_BINARY:=mount.cifs
CIFS_TARGET_BINARY:=/sbin/$(CIFS_BINARY)

$(DL_DIR)/$(CIFS_SOURCE):
	$(WGET) -O $(DL_DIR)/$(CIFS_SOURCE)  $(CIFS_URL)

$(CIFS_DIR)/$(CIFS_SOURCE): $(DL_DIR)/$(CIFS_SOURCE)
	test -d $(CIFS_DIR) || mkdir $(CIFS_DIR)
	cp $(DL_DIR)/$(CIFS_SOURCE) $(CIFS_DIR)

$(CIFS_DIR)/$(CIFS_BINARY): $(CIFS_DIR)/$(CIFS_SOURCE)
	$(TARGET_CC) -O2 -o $@ $<

$(TARGET_DIR)/$(CIFS_TARGET_BINARY):$(CIFS_DIR)/$(CIFS_BINARY)
	/usr/bin/install -c $(CIFS_DIR)/mount.cifs $(TARGET_DIR)/sbin
	-$(STRIP) --strip-unneeded $(TARGET_DIR)/$(CIFS_TARGET_BINARY)

cifs: uclibc $(TARGET_DIR)/$(CIFS_TARGET_BINARY)

cifs_source: $(DL_DIR)/$(CIFS_SOURCE)

cifs_clean:
	rm -f $(TARGET_DIR)/$(CIFS_TARGET_BINARY)
	rm -f $(CIFS_DIR)/mount.cifs $(CIFS_DIR)/mount.cifs.o

cifs_dirclean:
	rm -rf $(CIFS_DIR)

###############################################################################
#
# Toplevel Makefile options
#
###############################################################################
ifeq ($(strip $(BR2_PACKAGE_CIFS)),y)
TARGETS+=cifs
endif
