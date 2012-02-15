#############################################################
#
# usb_modeswitch
#
#############################################################

USB_MODESWITCH_VERSION = 1.2.3
USB_MODESWITCH_SOURCE = usb-modeswitch-$(USB_MODESWITCH_VERSION).tar.bz2
USB_MODESWITCH_DATA = usb-modeswitch-data-20120120.tar.bz2
USB_MODESWITCH_SITE = http://www.draisberghof.de/usb_modeswitch
USB_MODESWITCH_DEPENDENCIES = libusb
USB_MODESWITCH_DIR:=$(BUILD_DIR)/usb-modeswitch-$(USB_MODESWITCH_VERSION)
USB_MODESWITCH_BINARY=$(USB_MODESWITCH_DIR)/usb_modeswitch
USB_MODESWITCH_TARGET_BINARY = usr/sbin/usb_modeswitch
$(DL_DIR)/$(USB_MODESWITCH_SOURCE) $(DL_DIR)/$(USB_MODESWITCH_DATA):
	$(WGET) -P $(DL_DIR) $(USB_MODESWITCH_SITE)/$(USB_MODESWITCH_SOURCE)
	$(WGET) -P $(DL_DIR) $(USB_MODESWITCH_SITE)/$(USB_MODESWITCH_DATA)

$(USB_MODESWITCH_DIR)/.source: $(DL_DIR)/$(USB_MODESWITCH_SOURCE)
	bzip2 -d < $(DL_DIR)/$(USB_MODESWITCH_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	touch $(USB_MODESWITCH_DIR)/.source

$(USB_MODESWITCH_DIR)/$(USB_MODESWITCH_BINARY): $(USB_MODESWITCH_DIR)/.source
	$(MAKE) -C $(USB_MODESWITCH_DIR) \
                CC=$(TARGET_CC)  \
		CFLAGS="$(TARGET_CFLAGS)" \
                STRIP="$(STRIPCMD) $(STRIP_STRIP_ALL)" \

$(TARGET_DIR)/$(USB_MODESWITCH_TARGET_BINARY): $(USB_MODESWITCH_DIR)/$(USB_MODESWITCH_BINARY) $(DL_DIR)/$(USB_MODESWITCH_DATA)
	$(STRIPCMD) $(STRIP_STRIP_ALL)	$(USB_MODESWITCH_BINARY)
	/usr/bin/install -c $(USB_MODESWITCH_BINARY) $(TARGET_DIR)/usr/sbin
	/usr/bin/install -c $(USB_MODESWITCH_DIR)/usb_modeswitch.conf $(TARGET_DIR)/etc

usb_modeswitch: uclibc libusb $(TARGET_DIR)/$(USB_MODESWITCH_TARGET_BINARY)

usb_modeswitch_source: $(DL_DIR)/$(USB_MODESWITCH_SOURCE)

usb_modeswitch_clean:
	rm -f $(TARGET_DIR)/$(USB_MODESWITCH_TARGET_BINARY)
	rm -f $(TARGET_DIR)/etc/usb_modeswitch.setup
	rm -f $(TARGET_DIR)/usr/share/man/man1/usb_modeswitch.1

usb_modeswitch_dirclean:
	rm -rf $(USB_MODESWITCH_DIR)

###############################################################################
#
# Toplevel Makefile options
#
###############################################################################
ifeq ($(strip $(BR2_PACKAGE_USB_MODESWITCH)),y)
TARGETS+=usb_modeswitch
endif



