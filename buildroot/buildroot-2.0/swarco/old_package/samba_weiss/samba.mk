#############################################################
#
# samba
#
#############################################################
SAMBA_VER:=2.2.3a
SAMBA_SOURCE:=samba_$(SAMBA_VER).tar.gz
SAMBA_SITE:=http://
SAMBA_DIR:=$(BUILD_DIR)/samba-$(SAMBA_VER)
SAMBA_BINARY:=$(SAMBA_DIR)/samba
SAMBA_TARGET_BINARY:=$(TARGET_DIR)/bin/samba
SAMBA_PDIR=$(PWD)/package/samba
SAMBA_CONFIG_H=$(SAMBA_DIR)/source/include/config.h
SAMBA_HOST_TOOLS=bin/make_smbcodepage   \
		 bin/make_unicodemap

$(DL_DIR)/$(SAMBA_SOURCE):
	 $(WGET) -P $(DL_DIR) $(SAMBA_SITE)/$(SAMBA_SOURCE)

samba-source: $(DL_DIR)/$(SAMBA_SOURCE)

$(SAMBA_DIR)/.unpacked: $(DL_DIR)/$(SAMBA_SOURCE)
	zcat $(DL_DIR)/$(SAMBA_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	touch $(SAMBA_DIR)/.unpacked

$(SAMBA_DIR)/.configured: $(SAMBA_DIR)/.unpacked
	#2006-05-30 gc: first build host tools
	(cd $(SAMBA_DIR)/source; \
		./configure \
	);
	$(MAKE) -C $(SAMBA_DIR)/source $(SAMBA_HOST_TOOLS)
	cp -a $(SAMBA_DIR)/source/bin $(SAMBA_DIR)/source/bin-host
	$(MAKE) -C $(SAMBA_DIR)/source clean
	#2006-05-30 gc: reconfigure for target
	-rm $(SAMBA_DIR)/source/config.cache
	(cd $(SAMBA_DIR)/source; \
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
	echo >>$(SAMBA_CONFIG_H) '#undef SIZEOF_INT'
	echo >>$(SAMBA_CONFIG_H) '#undef SIZEOF_LONG'
	echo >>$(SAMBA_CONFIG_H) '#undef SIZEOF_SHORT'
	echo >>$(SAMBA_CONFIG_H) '#define SIZEOF_INT 4'
	echo >>$(SAMBA_CONFIG_H) '#define SIZEOF_LONG 4'
	echo >>$(SAMBA_CONFIG_H) '#define SIZEOF_SHORT 2'
	# 2006-05-30 gc: add wrong detected items
	echo >>$(SAMBA_CONFIG_H) '#define HAVE_MMAP 1'
	echo >>$(SAMBA_CONFIG_H) '#define HAVE_LONGLONG 1'
	echo >>$(SAMBA_CONFIG_H) '#define HAVE_FCNTL_LOCK 1'
	echo >>$(SAMBA_CONFIG_H) '#define HAVE_GETTIMEOFDAY_TZ'
	echo >>$(SAMBA_CONFIG_H) '#define STAT_STATVFS 1'
	echo >>$(SAMBA_CONFIG_H) '#define HAVE_IFACE_IFCONF 1'
	echo >>$(SAMBA_CONFIG_H) '#define HAVE_KERNEL_SHARE_MODES 1'
	echo >>$(SAMBA_CONFIG_H) '#define HAVE_KERNEL_OPLOCKS_LINUX 1'
	echo >>$(SAMBA_CONFIG_H) '#define HAVE_KERNEL_CHANGE_NOTIFY 1'
	echo >>$(SAMBA_CONFIG_H) ''
	#
	touch  $(SAMBA_DIR)/.configured
	(cd $(SAMBA_DIR)/source; \
		touch $(SAMBA_HOST_TOOLS) \
	)

$(SAMBA_BINARY): $(SAMBA_DIR)/.configured
	$(MAKE) -C $(SAMBA_DIR)/source CC=$(TARGET_CC) CONFIGDIR=/etc/samba 

$(SAMBA_TARGET_BINARY): $(SAMBA_BINARY)
	cp -a $(SAMBA_DIR)/source/bin-host/* $(SAMBA_DIR)/source/bin
	$(MAKE) -C $(SAMBA_DIR)/source \
		BASEDIR=$(TARGET_DIR)/usr \
		prefix=$(TARGET_DIR)/usr  \
		LIBDIR=$(TARGET_DIR)/usr/lib \
		"CODEPAGELIST=850 ISO8859-1" \
		CC=$(TARGET_CC) \
		all installscripts install
	#cp $(SAMBA_DIR)/source/bin/nmbd $(TARGET_DIR)/bin
	#cp $(SAMBA_DIR)/source/bin/smbmount $(TARGET_DIR)/bin
	mkdir -p $(TARGET_DIR)/etc/samba
	cp $(SAMBA_DIR)/examples/simple/smb.conf $(TARGET_DIR)/etc/samba/smb.conf
	mkdir -p $(TARGET_DIR)/usr/lib/codepages
	#cp $(SAMBA_DIR)/source/codepages/codepage_def.850 $(TARGET_DIR)/usr/lib/codepages/codepage.850
		#installbin installscripts installcp
	rm -rf $(TARGET_DIR)/share/locale $(TARGET_DIR)/usr/info \
		$(TARGET_DIR)/usr/man $(TARGET_DIR)/usr/share/doc
	-rm $(TARGET_DIR)/usr/bin/*.old
	ln -fs /usr/bin/smbmount $(TARGET_DIR)/sbin/mount.smbfs


samba: uclibc $(SAMBA_TARGET_BINARY)

samba-clean:
	$(MAKE) DESTDIR=$(TARGET_DIR) CC=$(TARGET_CC) -C $(SAMBA_DIR)/source uninstall
	-$(MAKE) -C $(SAMBA_DIR) clean

samba-dirclean:
	rm -rf $(SAMBA_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(strip $(BR2_PACKAGE_SAMBA_WEISS)),y)
TARGETS+=samba
endif
