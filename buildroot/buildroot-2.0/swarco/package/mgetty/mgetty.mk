#############################################################
#
# mgetty
#
#############################################################
MGETTY_VER:=1.1.35
MGETTY_SOURCE:=mgetty-$(MGETTY_VER).tar.gz
MGETTY_SITE:=http://
MGETTY_DIR:=$(BUILD_DIR)/mgetty-$(MGETTY_VER)
MGETTY_BINARY:=$(MGETTY_DIR)/mgetty
MGETTY_CONFDIR:=$(TARGET_DIR)/etc/mgetty
MGETTY_TARGET_BINARY:=$(TARGET_DIR)/bin/mgetty
MGETTY_P_DIR:=$(BUILD_DIR)/../swarco/package/mgetty
$(DL_DIR)/$(MGETTY_SOURCE):
	 $(WGET) -P $(DL_DIR) $(MGETTY_SITE)/$(MGETTY_SOURCE)

$(MGETTY_DIR)/.unpacked: $(DL_DIR)/$(MGETTY_SOURCE)
	zcat $(DL_DIR)/$(MGETTY_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
#	cp $(MGETTY_P_DIR)/mod_exec.c $(MGETTY_DIR)/modules/
	cp $(MGETTY_P_DIR)/policy.h $(MGETTY_DIR)/policy.h
	patch $(MGETTY_DIR)/logfile.c < $(MGETTY_P_DIR)/logfile.patch 
	patch -p1 $(MGETTY_DIR)/Makefile < $(MGETTY_P_DIR)/mgetty_make.patch
	#cp $(MGETTY_DIR)/policy.h-dist $(MGETTY_DIR)/policy.h
	touch $(MGETTY_DIR)/.unpacked

$(MGETTY_BINARY): $(MGETTY_DIR)/.unpacked
	$(MAKE1) -C $(MGETTY_DIR) CC=$(TARGET_CC) mgetty

$(MGETTY_TARGET_BINARY):$(MGETTY_BINARY)
	$(MAKE1) prefix=$(TARGET_DIR)/usr -C $(MGETTY_DIR) mgetty
	#$(MAKE1) prefix=$(TARGET_DIR)/usr -C $(MGETTY_DIR)/callback callback
	cp $(MGETTY_DIR)/mgetty $(TARGET_DIR)/sbin 
	#test -f $(MGETTY_CONFDIR)/mgetty.config || \
	mkdir -p $(MGETTY_CONFDIR)
	#cp $(MGETTY_DIR)/mgetty.cfg.in $(MGETTY_CONFDIR)/mgetty.config
	#cp $(MGETTY_DIR)/login.cfg.in $(MGETTY_CONFDIR)/login.config
	#test -f $(MGETTY_CONFDIR)/login.config || \
	#	$(INSTALL) -m 600 login.config $(MGETTY_CONFDIR)/
	#test -f $(MGETTY_CONFDIR)/mgetty.config || \
	#	$(INSTALL) -m 600 mgetty.config $(MGETTY_CONFDIR)/

mgetty: uclibc $(MGETTY_TARGET_BINARY)

mgetty-clean:
	$(MAKE1) DESTDIR=$(TARGET_DIR) CC=$(TARGET_CC) -C $(MGETTY_DIR)/source uninstall
	-$(MAKE) -C $(MGETTY_DIR) clean

mgetty-dirclean:
	rm -rf $(MGETTY_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(strip $(BR2_PACKAGE_MGETTY)),y)
TARGETS+=mgetty
endif
