#############################################################
#
# ser2net
#
#############################################################

SER2NET_VERSION = 2.7
SER2NET_SOURCE = ser2net-$(SER2NET_VERSION).tar.gz
SER2NET_SITE = http://downloads.sourceforge.net/project/ser2net/ser2net/2.7/
SER2NET_DIR:=$(BUILD_DIR)/ser2net-$(SER2NET_VERSION)
SER2NET_BINARY:=ser2net
SER2NET_TARGET_BINARY:=/usr/sbin/ser2net


$(DL_DIR)/$(SER2NET_SOURCE):
	$(WGET) -P $(DL_DIR) $(SER2NET_SITE)/$(SER2NET_SOURCE)

$(SER2NET_DIR)/.source: $(DL_DIR)/$(SER2NET_SOURCE)
	zcat $(DL_DIR)/$(SER2NET_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	touch $(SER2NET_DIR)/.source

$(SER2NET_DIR)/.configured: $(SER2NET_DIR)/.source
	(cd $(SER2NET_DIR); \
		$(TARGET_CONFIGURE_OPTS) \
		CFLAGS="$(TARGET_CFLAGS)" \
	        ./configure \
		--target=$(GNU_TARGET_NAME) \
		--host=$(GNU_TARGET_NAME) \
		--build=$(GNU_HOST_NAME) \
		--prefix=/usr/ \
		--includedir=$(STAGING_DIR)/include \
		--sysconfdir=$(TARGET_DIR)/etc \
	);
	touch $(SER2NET_DIR)/.configured;

$(SER2NET_DIR)/$(SER2NET_BINARY): $(SER2NET_DIR)/.configured
	$(MAKE) -C $(SER2NET_DIR) \
                CC=$(TARGET_CC)  \
                STRIP="$(STRIPCMD) $(STRIP_STRIP_ALL)" \
	        CFLAGS=" -g -Os -pipe  -funsigned-char -falign-functions=0"

$(TARGET_DIR)/$(SER2NET_TARGET_BINARY):$(SER2NET_DIR)/$(SER2NET_BINARY)
	/usr/bin/install -c $(SER2NET_DIR)/$(SER2NET_BINARY) $(TARGET_DIR)/$(SER2NET_TARGET_BINARY)

ser2net: uclibc $(TARGET_DIR)/$(SER2NET_TARGET_BINARY)

ser2net_source: $(DL_DIR)/$(SER2NET_SOURCE)

ser2net_clean:
	$(MAKE) prefix=$(TARGET_DIR)/usr -C $(SER2NET_DIR) uninstall -$(MAKE) -C $(SER2NET_DIR) clean

ser2net_dirclean:
	rm -rf $(SER2NET_DIR)

###############################################################################
#
# Toplevel Makefile options
#
###############################################################################
ifeq ($(strip $(BR2_PACKAGE_SER2NET)),y)
TARGETS+=ser2net
endif
