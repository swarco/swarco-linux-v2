#############################################################
#
# nmbd
#
#############################################################
NMBD_VER:=2.2.3a
NMBD_SOURCE:=samba_$(NMBD_VER).tar.gz
NMBD_SITE:=http://
NMBD_DIR:=$(BUILD_DIR)/samba-$(NMBD_VER)
NMBD_BINARY:=$(NMBD_DIR)/nmbd
NMBD_TARGET_BINARY:=$(TARGET_DIR)/bin/nmbd
NMBD_PDIR=$(PWD)/package/nmbd
NMBD_CONFIG_H=$(NMBD_DIR)/source/include/config.h
NMBD_HOST_TOOLS=bin/make_smbcodepage   \
		 bin/make_unicodemap

$(DL_DIR)/$(NMBD_SOURCE):
	 $(WGET) -P $(DL_DIR) $(NMBD_SITE)/$(NMBD_SOURCE)

nmbd-source: $(DL_DIR)/$(NMBD_SOURCE)

$(NMBD_DIR)/.unpacked: $(DL_DIR)/$(NMBD_SOURCE)
	zcat $(DL_DIR)/$(NMBD_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	touch $(NMBD_DIR)/.unpacked

$(NMBD_DIR)/.configured: $(NMBD_DIR)/.unpacked
	#2006-05-30 gc: first build host tools
	(cd $(NMBD_DIR)/source; \
		./configure \
	);
	$(MAKE) -C $(NMBD_DIR)/source $(NMBD_HOST_TOOLS)
	cp -a $(NMBD_DIR)/source/bin $(NMBD_DIR)/source/bin-host
	$(MAKE) -C $(NMBD_DIR)/source clean
	#2006-05-30 gc: reconfigure for target
	-rm $(NMBD_DIR)/source/config.cache
	(cd $(NMBD_DIR)/source; \
		$(TARGET_CONFIGURE_OPTS) \
		CFLAGS="$(TARGET_CFLAGS)" \
		./configure \
		--disable-debug \
		--includedir=$(STAGING_DIR)/include \
		--libdir=/usr/lib \
		--target=$(GNU_TARGET_NAME) \
		--host=$(GNU_TARGET_NAME) \
		--build=$(GNU_HOST_NAME) \
		--prefix=/usr/local \
		--with-distro=none \
		--without-smbmount \
	);
	echo >>$(NMBD_CONFIG_H) '#undef SIZEOF_INT'
	echo >>$(NMBD_CONFIG_H) '#undef SIZEOF_LONG'
	echo >>$(NMBD_CONFIG_H) '#undef SIZEOF_SHORT'
	echo >>$(NMBD_CONFIG_H) '#define SIZEOF_INT 4'
	echo >>$(NMBD_CONFIG_H) '#define SIZEOF_LONG 4'
	echo >>$(NMBD_CONFIG_H) '#define SIZEOF_SHORT 2'
	# 2006-05-30 gc: add wrong detected items
	echo >>$(NMBD_CONFIG_H) '#define HAVE_MMAP 1'
	echo >>$(NMBD_CONFIG_H) '#define HAVE_LONGLONG 1'
	echo >>$(NMBD_CONFIG_H) '#define HAVE_FCNTL_LOCK 1'
	echo >>$(NMBD_CONFIG_H) '#define HAVE_GETTIMEOFDAY_TZ'
	echo >>$(NMBD_CONFIG_H) '#define STAT_STATVFS 1'
	echo >>$(NMBD_CONFIG_H) '#define HAVE_IFACE_IFCONF 1'
	echo >>$(NMBD_CONFIG_H) '#define HAVE_KERNEL_SHARE_MODES 1'
	echo >>$(NMBD_CONFIG_H) '#define HAVE_KERNEL_OPLOCKS_LINUX 1'
	echo >>$(NMBD_CONFIG_H) '#define HAVE_KERNEL_CHANGE_NOTIFY 1'
	echo >>$(NMBD_CONFIG_H) ''
	#
	touch  $(NMBD_DIR)/.configured
	(cd $(NMBD_DIR)/source; \
		touch $(NMBD_HOST_TOOLS) \
	)

$(NMBD_BINARY): $(NMBD_DIR)/.configured
	$(MAKE) -C $(NMBD_DIR)/source CC=$(TARGET_CC) CONFIGDIR=/etc/samba 

$(NMBD_TARGET_BINARY): $(NMBD_BINARY)
	cp -a $(NMBD_DIR)/source/bin-host/* $(NMBD_DIR)/source/bin
	$(MAKE) -C $(NMBD_DIR)/source \
		BASEDIR=$(TARGET_DIR)/usr \
		prefix=$(TARGET_DIR)/usr  \
		LIBDIR=$(TARGET_DIR)/usr/lib \
		"CODEPAGELIST=850 ISO8859-1" \
		CC=$(TARGET_CC) \
		all installscripts
	cp $(NMBD_DIR)/source/bin/nmbd $(TARGET_DIR)/bin
	#cp $(NMBD_DIR)/source/bin/smbmount $(TARGET_DIR)/bin
	mkdir -p $(TARGET_DIR)/etc/samba
	cp $(NMBD_DIR)/examples/simple/smb.conf $(TARGET_DIR)/etc/samba/smb.conf
	mkdir -p $(TARGET_DIR)/usr/lib/codepages
	#cp $(NMBD_DIR)/source/codepages/codepage_def.850 $(TARGET_DIR)/usr/lib/codepages/codepage.850
		#installbin installscripts installcp
	rm -rf $(TARGET_DIR)/share/locale $(TARGET_DIR)/usr/info \
		$(TARGET_DIR)/usr/man $(TARGET_DIR)/usr/share/doc
	-rm $(TARGET_DIR)/usr/bin/*.old
	ln -fs /usr/bin/smbmount $(TARGET_DIR)/sbin/mount.smbfs


nmbd: uclibc $(NMBD_TARGET_BINARY)

nmbd-clean:
	$(MAKE) DESTDIR=$(TARGET_DIR) CC=$(TARGET_CC) -C $(NMBD_DIR)/source uninstall
	-$(MAKE) -C $(NMBD_DIR) clean

nmbd-dirclean:
	rm -rf $(NMBD_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(strip $(BR2_PACKAGE_NMBD)),y)
TARGETS+=nmbd
endif
