#############################################################
#
# openssh
#
#############################################################
OPENSSH_VER:=4.5p1
OPENSSH_SITE:=ftp://ftp.openbsd.org/pub/OpenBSD/OpenSSH/portable
OPENSSH_DIR:=$(BUILD_DIR)/openssh-$(OPENSSH_VER)
OPENSSH_SOURCE:=openssh-$(OPENSSH_VER).tar.gz

$(DL_DIR)/$(OPENSSH_SOURCE):
	$(WGET) -P $(DL_DIR) $(OPENSSH_SITE)/$(OPENSSH_SOURCE)

$(OPENSSH_DIR)/.unpacked: $(DL_DIR)/$(OPENSSH_SOURCE)
	zcat $(DL_DIR)/$(OPENSSH_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
#	toolchain/patch-kernel.sh $(OPENSSH_DIR) package/openssh/ openssh\*.patch
	touch  $(OPENSSH_DIR)/.unpacked

$(OPENSSH_DIR)/.configured: $(OPENSSH_DIR)/.unpacked
	(cd $(OPENSSH_DIR); rm -rf config.cache; autoconf; \
		$(TARGET_CONFIGURE_OPTS) \
		LD=$(TARGET_CROSS)gcc \
		CFLAGS="$(TARGET_CFLAGS)" \
		./configure \
		--target=$(GNU_TARGET_NAME) \
		--host=$(GNU_TARGET_NAME) \
		--build=$(GNU_HOST_NAME) \
		--prefix=/usr \
		--exec-prefix=/usr \
		--bindir=/usr/bin \
		--sbindir=/usr/sbin \
		--libexecdir=/usr/sbin \
		--sysconfdir=/etc \
		--datadir=/usr/share \
		--localstatedir=/var \
		--mandir=/usr/man \
		--infodir=/usr/info \
		--with-random=/dev/urandom \
		--includedir=$(STAGING_DIR)/include \
		--disable-lastlog --disable-utmp \
		--disable-utmpx --disable-wtmp --disable-wtmpx \
		--without-x \
		$(DISABLE_NLS) \
		$(DISABLE_LARGEFILE) \
	);
	touch  $(OPENSSH_DIR)/.configured

$(OPENSSH_DIR)/ssh: $(OPENSSH_DIR)/.configured
	$(MAKE) CC=$(TARGET_CC) -C $(OPENSSH_DIR)
	-$(STRIP) --strip-unneeded $(OPENSSH_DIR)/scp
	-$(STRIP) --strip-unneeded $(OPENSSH_DIR)/sftp
	-$(STRIP) --strip-unneeded $(OPENSSH_DIR)/sftp-server
	-$(STRIP) --strip-unneeded $(OPENSSH_DIR)/ssh
	-$(STRIP) --strip-unneeded $(OPENSSH_DIR)/ssh-add
	-$(STRIP) --strip-unneeded $(OPENSSH_DIR)/ssh-agent
	-$(STRIP) --strip-unneeded $(OPENSSH_DIR)/ssh-keygen
	-$(STRIP) --strip-unneeded $(OPENSSH_DIR)/ssh-keyscan
	-$(STRIP) --strip-unneeded $(OPENSSH_DIR)/ssh-keysign
	-$(STRIP) --strip-unneeded $(OPENSSH_DIR)/ssh-rand-helper
	-$(STRIP) --strip-unneeded $(OPENSSH_DIR)/sshd

$(TARGET_DIR)/usr/bin/ssh: $(OPENSSH_DIR)/ssh
	# mf 2006-05-30:
	# 	make install doesn't work with cross compiler for arm
	# 	therefore we use make all and cp the needet files manually
	# 	into target. 
	$(MAKE) CC=$(TARGET_CC) DESTDIR=$(TARGET_DIR) -C $(OPENSSH_DIR) all
	cp $(OPENSSH_DIR)/ssh $(TARGET_DIR)/usr/bin/ssh
	cp $(OPENSSH_DIR)/sshd $(TARGET_DIR)/usr/sbin/sshd
	cp $(OPENSSH_DIR)/scp $(TARGET_DIR)/usr/bin/scp
	cp $(OPENSSH_DIR)/ssh-add $(TARGET_DIR)/usr/bin/ssh-add
	cp $(OPENSSH_DIR)/ssh-agent $(TARGET_DIR)/usr/bin/ssh-agent
	cp $(OPENSSH_DIR)/ssh-keygen $(TARGET_DIR)/usr/bin/ssh-keygen
	cp $(OPENSSH_DIR)/ssh-keyscan $(TARGET_DIR)/usr/bin/ssh-keyscan
	#
	# 2007-02-14 gc: install sftp-server!!!
	sed 's#/usr/libexec/sftp-server#/usr/lib/sftp-server#g' \
	    < $(OPENSSH_DIR)/sshd_config                        \
	    > $(TARGET_DIR)/etc/sshd_config
	cp $(OPENSSH_DIR)/sftp-server $(TARGET_DIR)/usr/lib
	#
	mkdir -p $(TARGET_DIR)/etc/init.d/
	cp $(OPENSSH_DIR)/opensshd.init $(TARGET_DIR)/etc/init.d/S50sshd
	chmod a+x $(TARGET_DIR)/etc/init.d/S50sshd
	rm -rf $(TARGET_DIR)/usr/info $(TARGET_DIR)/usr/man $(TARGET_DIR)/usr/share/doc

openssh: openssl zlib $(TARGET_DIR)/usr/bin/ssh

openssh-source: $(DL_DIR)/$(OPENSSH_SOURCE)

openssh-clean: 
	$(MAKE) -C $(OPENSSH_DIR) clean

openssh-dirclean: 
	rm -rf $(OPENSSH_DIR)
#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(strip $(BR2_PACKAGE_OPENSSH)),y)
TARGETS+=openssh
endif
