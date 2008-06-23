##############################################################################
#
# updatedd
#
##############################################################################
UPDATEDD_VER:=2.3
UPDATEDD_SOURCE:=updatedd_$(UPDATEDD_VER).tar.gz
UPDATEDD_SITE:=http://
UPDATEDD_DIR:=$(BUILD_DIR)/updatedd-$(UPDATEDD_VER)
UPDATEDD_BINARY:=updatedd
UPDATEDD_TARGET_BINARY:=/usr/bin/updatedd


$(DL_DIR)/$(UPDATEDD_SOURCE):
	$(WGET) -P $(DL_DIR) $(UPDATEDD_SITE)/$(UPDATEDD_SOURCE)

$(UPDATEDD_DIR)/.source: $(DL_DIR)/$(UPDATEDD_SOURCE)
	zcat $(DL_DIR)/$(UPDATEDD_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	touch $(UPDATEDD_DIR)/.source

$(UPDATEDD_DIR)/.configured: $(UPDATEDD_DIR)/.source
	(cd $(UPDATEDD_DIR); \
		$(TARGET_CONFIGURE_OPTS) \
		CFLAGS="$(TARGET_CFLAGS)" \
	        ./configure \
		--target=$(GNU_TARGET_NAME) \
		--host=$(GNU_TARGET_NAME) \
		--build=$(GNU_HOST_NAME) \
		--prefix=/usr \
		--includedir=$(STAGING_DIR)/include \
		--oldincludedir=/usr/include \
		--sysconfdir=$(TARGET_DIR)/etc \
	);
	touch $(UPDATEDD_DIR)/.configured;

$(UPDATEDD_DIR)/$(UPDATEDD_BINARY): $(UPDATEDD_DIR)/.configured
	$(MAKE) CC=$(TARGET_CC) -C $(UPDATEDD_DIR)

$(TARGET_DIR)/$(UPDATEDD_TARGET_BINARY):$(UPDATEDD_DIR)/$(UPDATEDD_BINARY)
	$(MAKE) prefix=$(TARGET_DIR)/usr -C $(UPDATEDD_DIR) install
	rm -Rf $(TARGET_DIR)/usr/man

updatedd: uclibc $(TARGET_DIR)/$(UPDATEDD_TARGET_BINARY)

updatedd_source: $(DL_DIR)/$(UPDATEDD_SOURCE)

updatedd_clean:
	$(MAKE) prefix=$(TARGET_DIR)/usr -C $(UPDATEDD_DIR) uninstall -$(MAKE) -C $(UPDATEDD_DIR) clean

updatedd_dirclean:
	rm -rf $(UPDATEDD_DIR)

###############################################################################
#
# Toplevel Makefile options
#
###############################################################################
ifeq ($(strip $(BR2_PACKAGE_UPDATEDD)),y)
TARGETS+=updatedd
endif
