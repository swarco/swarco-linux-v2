#############################################################
#
# perl
#
#############################################################
PERL_VER=5.8.7
PERL_SOURCE=perl-$(PERL_VER).tar.bz2
PERL_SITE=ftp://ftp.cpan.org/pub/CPAN/src/5.0
PERL_DIR=$(BUILD_DIR)/perl-$(PERL_VER)
PERL_P_DIR=$(BUILD_DIR)/../package/perl

$(DL_DIR)/$(PERL_SOURCE):
	$(WGET) -P $(DL_DIR) $(PERL_SITE)/$(PERL_SOURCE)

$(PERL_DIR)/.source: $(DL_DIR)/$(PERL_SOURCE)
	bzcat $(DL_DIR)/$(PERL_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	touch $(PERL_DIR)/.source

$(PERL_DIR)/.host-perl:$(PERL_DIR)/.source
	(cd $(PERL_DIR); \
	#make -f Makefile.micro \
	-rm config.sh Policy.sh; \
	sh Configure -de; \
	make -j 5; \
	cp miniperl miniperl.native \
	);
	#rm -R  $(PERL_DIR)/*.o
	#mv $(PERL_DIR)/perl $(PERL_DIR)/host-perl
	#$(MAKE) -f Makefile.micro CC=$(TARGET_CC) -C $(PERL_DIR)
	-rm $(PERL_DIR)/config.sh
	-rm $(PERL_DIR)/Policy.sh
	chmod -R 777 $(PERL_DIR)
	cp $(PERL_P_DIR)/Configure $(PERL_DIR)
	cp $(PERL_DIR)/Cross/config.sh-arm-linux $(PERL_DIR)/config.sh
	touch $(PERL_DIR)/.host-perl

$(PERL_DIR)/.configured:$(PERL_DIR)/.host-perl
	(cd $(PERL_DIR); \
		cp $(PERL_P_DIR)/config.sh-arm-linux config.sh; \
		$(TARGET_CONFIGURE_OPTS) \
		CC="$(TARGET_CC)" \
		LD="$(TARGET_LD)" \
		ranlib="$(TARGET_RANLIB)" \
		CFLAGS="$(TARGET_CFLAGS)" \
		LDFLAGS="$(TARGET_LDFLAGS)" \
		./configure.gnu \
		--prefix=/usr/local \
		#sh Configure -S \
	);
	touch $(PERL_DIR)/.configured

$(PERL_DIR)/perl: $(PERL_DIR)/.configured
	-$(MAKE1) CC=$(TARGET_CC) -C $(PERL_DIR)
	-cp $(PERL_DIR)/miniperl.native $(PERL_DIR)/miniperl
	$(MAKE1) CC=$(TARGET_CC) -C $(PERL_DIR)

$(TARGET_DIR)/usr/bin/perl: $(PERL_DIR)/perl
	cp -dpf $(PERL_DIR)/perl $(TARGET_DIR)/usr/bin/perl

perl: uclibc $(TARGET_DIR)/usr/bin/perl

perl-source: $(DL_DIR)/$(PERL_SOURCE)

perl-clean:
	rm -f $(TARGET_DIR)/usr/bin/perl
	-$(MAKE) -C $(PERL_DIR) clean

perl-dirclean:
	rm -rf $(PERL_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(strip $(BR2_PACKAGE_PERL)),y)
TARGETS+=perl
endif
