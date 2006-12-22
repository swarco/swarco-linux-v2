####################################################################################
#
# sqlite
#
####################################################################################
SQLITE_VER:=2.8.17
SQLITE_SOURCE:=sqlite-$(SQLITE_VER).tar.gz
SQLITE_SITE:=http://bluez.sourceforge.net/download
SQLITE_DIR:=$(BUILD_DIR)/sqlite-$(SQLITE_VER)
SQLITE_BINARY:=sqlite
SQLITE_TARGET_BINARY:=/usr/bin/sqlite
PDIR=$(PWD)/package/sqlite


$(DL_DIR)/$(SQLITE_SOURCE):
	$(WGET) -P $(DL_DIR) $(SQLITE_SITE)/$(SQLITE_SOURCE)

$(SQLITE_DIR)/.source: $(DL_DIR)/$(SQLITE_SOURCE)
	zcat $(DL_DIR)/$(SQLITE_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	patch $(SQLITE_DIR)/configure < $(PDIR)/patch-cross-config
	touch $(SQLITE_DIR)/.source

$(SQLITE_DIR)/.configured: $(SQLITE_DIR)/.source
	(cd $(SQLITE_DIR); \
		$(TARGET_CONFIGURE_OPTS) \
		CFLAGS="$(TARGET_CFLAGS)" \
		./configure \
		--build=$(GNU_HOST_NAME) \
		--target=$(GNU_HOST_NAME) \
		--host=$(GNU_TARGET_NAME) \
		--prefix=/usr/local \
		--disable-tcl \
		--disable-readline \
		--without-readline \
		--with-gnu-ld \
		--libdir=$(SQLITE_DIR)/.libs \
	);
	touch $(SQLITE_DIR)/.configured;


$(SQLITE_DIR)/$(SQLITE_BINARY): $(SQLITE_DIR)/.configured
	patch $(SQLITE_DIR)/Makefile < $(PDIR)/make-patch.patch
	\rm -f $(SQLITE_DIR)/lemon
	\rm -f $(SQLITE_IDR)/temp
	$(MAKE) CC=$(TARGET_CC) -C $(SQLITE_DIR)

$(TARGET_DIR)/$(SQLITE_TARGET_BINARY):$(SQLITE_DIR)/$(SQLITE_BINARY)
	$(MAKE) prefix=$(TARGET_DIR)/usr -C $(SQLITE_DIR) install
	rm -Rf $(TARGET_DIR)/usr/man

sqlite: uclibc ncurses $(TARGET_DIR)/$(SQLITE_TARGET_BINARY)

sqlite_source: $(DL_DIR)/$(SQLITE_SOURCE)

sqlite_clean:
	$(MAKE) prefix=$(TARGET_DIR)/usr -C $(SQLITE_DIR) uninstall -$(MAKE) -C $(SQLITE_DIR) clean

sqlite_dirclean:
	rm -rf $(SQLITE_DIR)

##########################################################################################
#
# Toplevel Makefile options
#
##########################################################################################
ifeq ($(strip $(BR2_PACKAGE_SQLITE)),y)
TARGETS+=sqlite
endif
