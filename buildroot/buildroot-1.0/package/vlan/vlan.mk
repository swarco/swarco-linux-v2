#############################################################
#
# vlan
#
#############################################################
VLAN_VER:=1.19
VLAN_SOURCE:=vlan.$(VLAN_VER).tar.gz
VLAN_SITE:=ftp://alpha.gnu.org/gnu/vlan
VLAN_DIR:=$(BUILD_DIR)/$VLAN_SOURCE
VLAN_CAT:=zcat
VLAN_BINARY:=$(VLAN_DIR)
VLAN_TARGET_BINARY:=$(TARGET_DIR)/sbin/vconfig
#VLAN_PDIR=package/vlan

#ifneq ($(BR2_LARGEFILE),y)
#VLAN_LARGEFILE="--disable-largefile"
#endif

$(DL_DIR)/$(VLAN_SOURCE):
	 $(WGET) -P $(DL_DIR) $(VLAN_SITE)/$(VLAN_SOURCE)

vlan-source: $(DL_DIR)/$(VLAN_SOURCE)

$(VLAN_DIR)/.unpacked: $(DL_DIR)/$(VLAN_SOURCE)
	$(VLAN_CAT) $(DL_DIR)/$(VLAN_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	touch $(VLAN_DIR)/.unpacked

$(VLAN_DIR)/.configured: $(VLAN_DIR)/.unpacked
#	(cd $(VLAN_DIR); rm -rf config.cache; \
#		$(TARGET_CONFIGURE_OPTS) \
#		CFLAGS="$(TARGET_CFLAGS)" \
#		./configure \
#		--target=$(GNU_TARGET_NAME) \
#		--host=$(GNU_TARGET_NAME) \
#		--build=$(GNU_HOST_NAME) \
#		--prefix=/usr \
#		--exec-prefix=/ \
#		--bindir=/bin \
#		--sbindir=/bin \
#		--libexecdir=/usr/lib \
#		--sysconfdir=/etc \
#		--datadir=/usr/share/misc \
#		--localstatedir=/var \
#		--mandir=/usr/man \
#		--infodir=/usr/info \
#		$(DISABLE_NLS) \
#		$(VLAN_LARGEFILE) \
#	);
	touch  $(VLAN_DIR)/.configured

$(VLAN_BINARY): $(VLAN_DIR)/.configured
	$(MAKE) CC=$(TARGET_CC) -C $(VLAN_DIR)/LINUX

$(VLAN_TARGET_BINARY): $(VLAN_BINARY)
	$(MAKE) DESTDIR=$(TARGET_DIR) CC=$(TARGET_CC) -C $(VLAN_DIR)/LINUX all
	#cp -R $(VLAN_DIR)/web $(TARGET_DIR)
	#rm -rf $(TARGET_DIR)/web/docs
	cp $(VLAN_DIR)/LINUX/vconfig $(VLAN_TARGET_BINARY)

vlan: uclibc $(VLAN_TARGET_BINARY)

vlan-clean:
	$(MAKE) DESTDIR=$(TARGET_DIR) CC=$(TARGET_CC) -C $(VLAN_DIR) uninstall
	-$(MAKE) -C $(VLAN_DIR) clean

vlan-dirclean:
	rm -rf $(VLAN_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(strip $(BR2_PACKAGE_VLAN)),y)
TARGETS+=vlan
endif
