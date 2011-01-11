##############################################################################
#
# qemacs
#
##############################################################################
QEMACS_VER:=0.3.1.cvs.20050713
QEMACS_SOURCE:=qemacs_$(QEMACS_VER).tar.gz
QEMACS_SITE:=http://
QEMACS_DIR:=$(BUILD_DIR)/qemacs
QEMACS_BINARY:=qe
QEMACS_TARGET_BINARY:=/usr/bin/qemacs


$(DL_DIR)/$(QEMACS_SOURCE):
	$(WGET) -P $(DL_DIR) $(QEMACS_SITE)/$(QEMACS_SOURCE)

$(QEMACS_DIR)/.source: $(DL_DIR)/$(QEMACS_SOURCE)
	zcat $(DL_DIR)/$(QEMACS_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	touch $(QEMACS_DIR)/.source

$(QEMACS_DIR)/.configured: $(QEMACS_DIR)/.source
	(cd $(QEMACS_DIR); \
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
		--enable-tiny \
		--disable-x11 \
		--disable-xv \
		--disable-xrender \
		--disable-html \
		--disable-png \
		--disable-plugins \
	);
	touch $(QEMACS_DIR)/.configured;

$(QEMACS_DIR)/$(QEMACS_BINARY): $(QEMACS_DIR)/.configured
	$(MAKE) -C $(QEMACS_DIR) \
                CC=$(TARGET_CC)  \
                STRIP="$(STRIPCMD) $(STRIP_STRIP_ALL)" \
	        CFLAGS=" -g -Os -pipe  -funsigned-char -falign-functions=0"

$(TARGET_DIR)/$(QEMACS_TARGET_BINARY):$(QEMACS_DIR)/$(QEMACS_BINARY)
	/usr/bin/install -c $(QEMACS_DIR)/qe $(TARGET_DIR)/usr/bin
	$(STRIPCMD) $(STRIP_STRIP_ALL) $(TARGET_DIR)/usr/bin/qe

qemacs: uclibc $(TARGET_DIR)/$(QEMACS_TARGET_BINARY)

qemacs_source: $(DL_DIR)/$(QEMACS_SOURCE)

qemacs_clean:
	$(MAKE) prefix=$(TARGET_DIR)/usr -C $(QEMACS_DIR) uninstall -$(MAKE) -C $(QEMACS_DIR) clean

qemacs_dirclean:
	rm -rf $(QEMACS_DIR)

###############################################################################
#
# Toplevel Makefile options
#
###############################################################################
ifeq ($(strip $(BR2_PACKAGE_QEMACS)),y)
TARGETS+=qemacs
endif
