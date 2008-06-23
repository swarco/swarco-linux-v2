include weiss/package/*/*.mk

.PHONY: install_chconf
install_chconf:
	echo install_chconf: 
	(cd weiss/ch_conf; tar cf - --exclude .svn .) | (cd $(TARGET_DIR);tar xvf -)


$(JFFS2_TARGET): install_chconf	

