####################################################################################
#
# bluez-libs
#
####################################################################################
BLUEZ-LIBS_VER:=2.25
BLUEZ-LIBS_SOURCE:=bluez-libs-$(BLUEZ-LIBS_VER).tar.gz
BLUEZ-LIBS_SITE:=http://bluez.sourceforge.net/download
BLUEZ-LIBS_DIR:=$(BUILD_DIR)/bluez-libs-$(BLUEZ-LIBS_VER)

DESTDIR:=$(TARGET_DIR)

$(DL_DIR)/$(BLUEZ-LIBS_SOURCE):
	$(WGET) -P $(DL_DIR) $(BLUEZ-LIBS_SITE)/$(BLUEZ-LIBS_SOURCE)

$(BLUEZ-LIBS_DIR)/.source: $(DL_DIR)/$(BLUEZ-LIBS_SOURCE)
	zcat $(DL_DIR)/$(BLUEZ-LIBS_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	toolchain/patch-kernel.sh $(BLUEZ-LIBS_DIR) weiss/package/bluez-libs/ bluez-libs\*.patch
	touch $(BLUEZ-LIBS_DIR)/.source

$(BLUEZ-LIBS_DIR)/.configured: $(BLUEZ-LIBS_DIR)/.source
	(cd $(BLUEZ-LIBS_DIR); \
		$(TARGET_CONFIGURE_OPTS) \
		CFLAGS="$(TARGET_CFLAGS)" \
		./configure \
		--target=$(GNU_TARGET_NAME) \
		--host=$(GNU_TARGET_NAME) \
		--build=$(GNU_HOST_NAME) \
		--prefix=/usr \
		--sysconfdir=/etc \
	);
	touch $(BLUEZ-LIBS_DIR)/.configured;

$(BLUEZ-LIBS_DIR)/libbluetooth.so.$(BLUEZ-LIBS_VER): $(BLUEZ-LIBS_DIR)/.configured
	$(MAKE) CC=$(TARGET_CC) -C $(BLUEZ-LIBS_DIR)

$(TARGET_DIR)/lib/libbluetooth.so.$(BLUEZ-LIBS_VER):$(BLUEZ-LIBS_DIR)/libbluetooth.so.$(BLUEZ-LIBS_VER)
	$(MAKE) prefix=$(TARGET_DIR)/usr -C $(BLUEZ-LIBS_DIR) all
	rm -Rf $(TARGET_DIR)/usr/man
	-mkdir -pv $(TARGET_DIR)/usr/include/bluetooth
	cp $(BLUEZ-LIBS_DIR)/src/.libs/* $(TARGET_DIR)/lib

bluez-libs: uclibc $(TARGET_DIR)/lib/libbluetooth.so.$(BLUEZ-LIBS_VER)

bluez-libs_source: $(DL_DIR)/$(BLUEZ-LIBS_SOURCE)

bluez-libs_clean:
	$(MAKE) prefix=$(TARGET_DIR)/usr -C $(BLUEZ-LIBS_DIR) uninstall -$(MAKE) -C $(BLUEZ-LIBS_DIR) clean

bluez-libs_dirclean:
	rm -rf $(BLUEZ-LIBS_DIR)

##########################################################################################
#
# Toplevel Makefile options
#
##########################################################################################
ifeq ($(strip $(BR2_PACKAGE_BLUEZ-LIBS)),y)
TARGETS+=bluez-libs
endif
