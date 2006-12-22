##############################################################################
#
# fuser
#
##############################################################################
FUSER_VER:=22.2
FUSER_SOURCE:=psmisc_$(FUSER_VER).tar.gz
FUSER_SITE:=http://
FUSER_DIR:=$(BUILD_DIR)/psmisc-$(FUSER_VER)
FUSER_BINARY:=fuser
FUSER_TARGET_BINARY:=/bin/fuser

$(DL_DIR)/$(FUSER_SOURCE):
	$(WGET) -P $(DL_DIR) $(FUSER_SITE)/$(FUSER_SOURCE)

$(FUSER_DIR)/.source: $(DL_DIR)/$(FUSER_SOURCE)
	zcat $(DL_DIR)/$(FUSER_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	touch $(FUSER_DIR)/.source

$(FUSER_DIR)/.configured: $(FUSER_DIR)/.source
	(cd $(FUSER_DIR); \
		$(TARGET_CONFIGURE_OPTS) \
		CFLAGS="$(TARGET_CFLAGS)" \
	        ./configure \
		--target=$(GNU_TARGET_NAME) \
		--host=$(GNU_TARGET_NAME) \
		--build=$(GNU_HOST_NAME) \
		--prefix=/usr/local \
		--includedir=$(STAGING_DIR)/include \
		--oldincludedir=/usr/include \
		--sysconfdir=$(TARGET_DIR)/etc \
	);
	touch $(FUSER_DIR)/.configured;

$(FUSER_DIR)/$(FUSER_BINARY): $(FUSER_DIR)/.configured
	$(MAKE) CC=$(TARGET_CC) -C $(FUSER_DIR)

$(TARGET_DIR)/$(FUSER_TARGET_BINARY):$(FUSER_DIR)/$(FUSER_BINARY)
	cp $(FUSER_DIR)/src/fuser $(DESTDIR)/bin

fuser: uclibc ncurses $(TARGET_DIR)/$(FUSER_TARGET_BINARY)

fuser_source: $(DL_DIR)/$(FUSER_SOURCE)

fuser_clean:
	$(MAKE) prefix=$(TARGET_DIR)/usr -C $(FUSER_DIR) uninstall -$(MAKE) -C $(FUSER_DIR) clean

fuser_dirclean:
	rm -rf $(FUSER_DIR)

##########################################################################################
#
# Toplevel Makefile options
#
##########################################################################################
ifeq ($(strip $(BR2_PACKAGE_FUSER)),y)
TARGETS+=fuser
endif
