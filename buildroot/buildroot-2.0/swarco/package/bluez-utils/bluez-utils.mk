####################################################################################
#
# bluez-utils
#
####################################################################################
BLUEZ-UTILS_VER:=2.25
BLUEZ-UTILS_SOURCE:=bluez-utils-$(BLUEZ-UTILS_VER).tar.gz
BLUEZ-UTILS_SITE:=http://bluez.sourceforge.net/download
BLUEZ-UTILS_DIR:=$(BUILD_DIR)/bluez-utils-$(BLUEZ-UTILS_VER)
BLUEZ-UTILS_BINARY:=bluez-utils
BLUEZ-UTILS_TARGET_BINARY:=/usr/bin/bluez-utils


$(DL_DIR)/$(BLUEZ-UTILS_SOURCE):
	$(WGET) -P $(DL_DIR) $(BLUEZ-UTILS_SITE)/$(BLUEZ-UTILS_SOURCE)

$(BLUEZ-UTILS_DIR)/.source: $(DL_DIR)/$(BLUEZ-UTILS_SOURCE)
	zcat $(DL_DIR)/$(BLUEZ-UTILS_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	toolchain/patch-kernel.sh $(BLUEZ-UTILS_DIR) swarco/package/bluez-utils/ bluez-utils\*.patch
	touch $(BLUEZ-UTILS_DIR)/.source

$(BLUEZ-UTILS_DIR)/.configured: $(BLUEZ-UTILS_DIR)/.source
	(cd $(BLUEZ-UTILS_DIR); \
		$(TARGET_CONFIGURE_OPTS) \
		LDFLAGS=-L$(BUILD_DIR)/bluez-libs-$(BLUEZ-UTILS_VER)/src/.libs \
		CFLAGS="$(TARGET_CFLAGS)" \
	        ./configure  --with-bluez=$(BUILD_DIR)/bluez-libs-$(BLUEZ-UTILS_VER)/ \
		--target=$(GNU_TARGET_NAME) \
		--host=$(GNU_TARGET_NAME) \
		--build=$(GNU_HOST_NAME) \
		--prefix=$(STAGING_DIR)/usr/ \
		--includedir=$(STAGING_DIR)/include \
		--oldincludedir=$(STAGING_DIR)/usr/include \
		--disable-alsa \
		--sysconfdir=/etc \
		--without-alsa \
	);
	touch $(BLUEZ-UTILS_DIR)/.configured;

$(BLUEZ-UTILS_DIR)/$(BLUEZ-UTILS_BINARY): $(BLUEZ-UTILS_DIR)/.configured
	$(MAKE) CC=$(TARGET_CC) -C $(BLUEZ-UTILS_DIR)

$(TARGET_DIR)/$(BLUEZ-UTILS_TARGET_BINARY):$(BLUEZ-UTILS_DIR)/$(BLUEZ-UTILS_BINARY)
	$(MAKE) prefix=$(TARGET_DIR)/usr sysconfdir=$(TARGET_DIR)/etc -C $(BLUEZ-UTILS_DIR) install
	rm -Rf $(TARGET_DIR)/usr/man
	# phyton script don't run on our system
	rm -f $(TARGET_DIR)/usr/bin/bluepin
	rm -f $(TARGET_DIR)/lib/sdp.o
	rm -f $(TARGET_DIR)/lib/hci.o
	rm -f $(TARGET_DIR)/lib/bluetooth.o
	rm -f $(TARGET_DIR)/lib/libbluetooth.a
	rm -f $(TARGET_DIR)/lib/libbluetooth.la
	rm -f $(TARGET_DIR)/lib/libbluetooth.lai


bluez-utils: uclibc bluez-libs $(TARGET_DIR)/$(BLUEZ-UTILS_TARGET_BINARY)

bluez-utils_source: $(DL_DIR)/$(BLUEZ-UTILS_SOURCE)

bluez-utils_clean:
	$(MAKE) prefix=$(TARGET_DIR)/usr -C $(BLUEZ-UTILS_DIR) uninstall -$(MAKE) -C $(BLUEZ-UTILS_DIR) clean

bluez-utils_dirclean:
	rm -rf $(BLUEZ-UTILS_DIR)

##########################################################################################
#
# Toplevel Makefile options
#
##########################################################################################
ifeq ($(strip $(BR2_PACKAGE_BLUEZ-UTILS)),y)
TARGETS+=bluez-utils
endif
