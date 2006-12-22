####################################################################################
#
# dialog
#
####################################################################################
DIALOG_VER:=1.0-20060221
DIALOG_SOURCE:=dialog_$(DIALOG_VER).tar.gz
DIALOG_SITE:=http://bluez.sourceforge.net/download
DIALOG_DIR:=$(BUILD_DIR)/dialog-$(DIALOG_VER)
DIALOG_BINARY:=dialog
DIALOG_TARGET_BINARY:=/usr/bin/dialog


$(DL_DIR)/$(DIALOG_SOURCE):
	$(WGET) -P $(DL_DIR) $(DIALOG_SITE)/$(DIALOG_SOURCE)

$(DIALOG_DIR)/.source: $(DL_DIR)/$(DIALOG_SOURCE)
	zcat $(DL_DIR)/$(DIALOG_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	touch $(DIALOG_DIR)/.source

$(DIALOG_DIR)/.configured: $(DIALOG_DIR)/.source
	(cd $(DIALOG_DIR); \
		$(TARGET_CONFIGURE_OPTS) \
		LDFLAGS=-L$(BUILD_DIR)/bluez-libs-$(DIALOG_VER)/src/.libs \
		CFLAGS="$(TARGET_CFLAGS)" \
	        ./configure  --with-bluez=$(BUILD_DIR)/bluez-libs-$(DIALOG_VER)/ \
		--target=$(GNU_TARGET_NAME) \
		--host=$(GNU_TARGET_NAME) \
		--build=$(GNU_HOST_NAME) \
		--prefix=/usr/local \
		--includedir=$(STAGING_DIR)/include \
		--oldincludedir=/usr/include \
		--disable-alsa \
		--sysconfdir=$(TARGET_DIR)/etc \
		--without-alsa \
	);
	touch $(DIALOG_DIR)/.configured;

$(DIALOG_DIR)/$(DIALOG_BINARY): $(DIALOG_DIR)/.configured
	$(MAKE) CC=$(TARGET_CC) -C $(DIALOG_DIR)

$(TARGET_DIR)/$(DIALOG_TARGET_BINARY):$(DIALOG_DIR)/$(DIALOG_BINARY)
	$(MAKE) prefix=$(TARGET_DIR)/usr -C $(DIALOG_DIR) install
	rm -Rf $(TARGET_DIR)/usr/man

dialog: uclibc ncurses $(TARGET_DIR)/$(DIALOG_TARGET_BINARY)

dialog_source: $(DL_DIR)/$(DIALOG_SOURCE)

dialog_clean:
	$(MAKE) prefix=$(TARGET_DIR)/usr -C $(DIALOG_DIR) uninstall -$(MAKE) -C $(DIALOG_DIR) clean

dialog_dirclean:
	rm -rf $(DIALOG_DIR)

##########################################################################################
#
# Toplevel Makefile options
#
##########################################################################################
ifeq ($(strip $(BR2_PACKAGE_DIALOG)),y)
TARGETS+=dialog
endif
