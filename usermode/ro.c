/** 
 *  @file          ro.c
 *
 *                 Wrapper to mount root-fs readonly  
 *
 *  @version       0.0.7 (\$Revision$)
 *  @author        Markus Forster <br>
 *                 Weiss-Electronic GmbH
 *  
 *  $LastChangedBy$  
 *  $Date$
 *
 *  @par Modification History:
 *     - 2007-05-09 mf: Initial Version (Weiss Auto Logout)
 */  
 /****************************************************************************/
/* standard icludes */
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include <sys/types.h>

int main ()
{
  printf("Mounting root-fs readonly.\n");
  execl("/bin/mount", "mount", "-oremount,ro", "/", NULL);

  return 0;
}
