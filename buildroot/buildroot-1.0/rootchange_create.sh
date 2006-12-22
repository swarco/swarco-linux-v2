#! /bin/bash
#*****************************************************************************
#* 
#*  @file          rootchange_create.sh
#*
#*  Builds tarball of changed configuration files for Weiss CCM2200
#*
#*  @version       1.0 (\$Revision$)
#*  @author        Makrkus Forster <br>
#*                 Weiss-Electronic GmbH
#* 
#*  $LastChangedBy$  
#*  $Date$
#*  $URL$
#*
#*  @par Modification History:
#*    2006-04-28 mf: initial version (unixdef)
#*
#*  
#*****************************************************************************

mkdir temp_root
cp -a ch_conf/* temp_root
find temp_root -type d -name ".svn" -exec rm -rf '{}' \;
cd temp_root
tar -c * > ../root_changes.tar
cd ..
rm -rf temp_root