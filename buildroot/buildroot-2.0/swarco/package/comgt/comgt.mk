# Makefile comgt package Weiss-Embedded Linux
# (package formerly called "gcom")
# (C) 2007 Guido Classen, Weiss-Electronic GmbH
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

COMGT_VER:=0.32
COMGT_SOURCE:=comgt.$(COMGT_VER).tgz
COMGT_SITE:= http://downloads.sourceforge.net/comgt
COMGT_DIR:=$(BUILD_DIR)/comgt.$(COMGT_VER)
COMGT_CAT:=zcat
COMGT_BINARY:=$(COMGT_DIR)/comgt
COMGT_TARGET_BINARY:=$(TARGET_DIR)/usr/bin/comgt
COMGT_PDIR=weiss/package/comgt

$(DL_DIR)/$(COMGT_SOURCE):
	 $(WGET) -P $(DL_DIR) $(COMGT_SITE)/$(COMGT_SOURCE)

comgt-source: $(DL_DIR)/$(COMGT_SOURCE)

$(COMGT_DIR)/.unpacked: $(DL_DIR)/$(COMGT_SOURCE)
	$(COMGT_CAT) $(DL_DIR)/$(COMGT_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	patch -p1 -d $(COMGT_DIR) < $(COMGT_PDIR)/001-Makefile.patch
	touch $(COMGT_DIR)/.unpacked

$(COMGT_DIR)/.configured: $(COMGT_DIR)/.unpacked
	touch $@

$(COMGT_BINARY): $(COMGT_DIR)/.configured
	$(MAKE) -C $(COMGT_DIR) \
		CC="$(TARGET_CC)" \
		CFLAGS="$(TARGET_CFLAGS)" \
		comgt
	touch $@

$(COMGT_TARGET_BINARY): $(COMGT_BINARY)
	cp -af $(COMGT_BINARY) $(COMGT_TARGET_BINARY)
	$(STRIPCMD) $(STRIP_STRIP_ALL) $(COMGT_TARGET_BINARY)

comgt: uclibc $(COMGT_TARGET_BINARY)

comgt-clean:
	$(MAKE) DESTDIR=$(TARGET_DIR) CC=$(TARGET_CC) -C $(COMGT_DIR) uninstall
	-$(MAKE) -C $(COMGT_DIR) clean

comgt-dirclean:
	rm -rf $(COMGT_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(strip $(BR2_PACKAGE_COMGT)),y)
TARGETS+=comgt
endif
