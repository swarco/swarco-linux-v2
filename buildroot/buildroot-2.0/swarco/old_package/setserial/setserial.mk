##############################################################################
#
# setserial
#
##############################################################################
SETSERIAL_VER:=2.17
SETSERIAL_SOURCE:=setserial_$(SETSERIAL_VER).tar.gz
SETSERIAL_SITE:=http://
SETSERIAL_DIR:=$(BUILD_DIR)/setserial-$(SETSERIAL_VER)
SETSERIAL_BINARY:=setserial
SETSERIAL_TARGET_BINARY:=/usr/bin/setserial


$(DL_DIR)/$(SETSERIAL_SOURCE):
	$(WGET) -P $(DL_DIR) $(SETSERIAL_SITE)/$(SETSERIAL_SOURCE)

$(SETSERIAL_DIR)/.source: $(DL_DIR)/$(SETSERIAL_SOURCE)
	zcat $(DL_DIR)/$(SETSERIAL_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	touch $(SETSERIAL_DIR)/.source

$(SETSERIAL_DIR)/.configured: $(SETSERIAL_DIR)/.source
	(cd $(SETSERIAL_DIR); \
		$(TARGET_CONFIGURE_OPTS) \
		CFLAGS="$(TARGET_CFLAGS)" \
	        ./configure \
		--target=$(GNU_TARGET_NAME) \
		--host=$(GNU_TARGET_NAME) \
		--build=$(GNU_HOST_NAME) \
		--prefix=/usr/ \
		--includedir=$(STAGING_DIR)/include \
		--oldincludedir=/usr/include \
		--sysconfdir=$(TARGET_DIR)/etc \
	);
	touch $(SETSERIAL_DIR)/.configured;

$(SETSERIAL_DIR)/$(SETSERIAL_BINARY): $(SETSERIAL_DIR)/.configured
	$(MAKE) CC=$(TARGET_CC) -C $(SETSERIAL_DIR)

$(TARGET_DIR)/$(SETSERIAL_TARGET_BINARY):$(SETSERIAL_DIR)/$(SETSERIAL_BINARY)
	/usr/bin/install -c $(SETSERIAL_DIR)/setserial $(TARGET_DIR)/usr/bin
	$(STRIP) $(TARGET_DIR)/usr/bin/setserial

setserial: uclibc $(TARGET_DIR)/$(SETSERIAL_TARGET_BINARY)

setserial_source: $(DL_DIR)/$(SETSERIAL_SOURCE)

setserial_clean:
	$(MAKE) prefix=$(TARGET_DIR)/usr -C $(SETSERIAL_DIR) uninstall -$(MAKE) -C $(SETSERIAL_DIR) clean

setserial_dirclean:
	rm -rf $(SETSERIAL_DIR)

##########################################################################################
#
# Toplevel Makefile options
#
##########################################################################################
ifeq ($(strip $(BR2_PACKAGE_SETSERIAL)),y)
TARGETS+=setserial
endif
