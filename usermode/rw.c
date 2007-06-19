/*****************************************************************************/
/** 
 *  @file          rw.c
 *
 *                 Wrapper to mount root-fs readwrite  
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
  char *prog[] = {"mount", "-oremount,rw", "/", (char *)0};
 
  if (setuid(0) < 0)
    perror("Fehler bei den Rechten");
 
  fprintf(stderr, "Mounting root-fs readwrite.\n");
  execve("/bin/mount", prog, NULL);

  return 0;
}
