/*
Programm compilieren		: 	cc dcf77.c -O6 -o dcf77

Programm und Hardware testen	:	dcf77 -d3
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <termios.h>
#include <unistd.h>
#include <fcntl.h>
#include <time.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <sys/timex.h>

#define inb(port) 0               /* we use only serial communication */

//#define KC(a,b,c) (a<<16|b<<8|c)

#if 1 //LINUX_VERSION_CODE >= KC(1,3,0)
# define T_MODE modes
# define T_FREQ freq
#else
# define T_MODE mode
# define T_FREQ frequency
#endif

char *command;

/* DCF77 connected to: */
enum source {S_GAMEPORT, S_TTY} source = S_GAMEPORT;

/* Gameport at: */
unsigned port = 0x201, portbit = 4;

/* TTY to use: */
char tty[256] = "/dev/dcf77";

/* set the clock.  bit 0 = every minute,  bit 1 = once using settimeofday 
 * bit 2 = always use settimeofday
 */
int setunix = 0;

/* publish settings to mosquitto */
int publish_settings = 0;

int tick = 0;

unsigned deb = 0;
#define D_ALLBITS 1
#define D_EDGE 2

#ifdef BODODEBUG
#define D_DEBUG 4
#define D_VERBOSE 8
#endif

#define POLL_DISTANCE 10000

FILE *fp_data;

void settings_value(const char *path, const char *id, const char *value)
{
  char buffer[1024];
  snprintf(buffer, sizeof(buffer)-1, 
          "mosquitto_pub -r -t 'settings/c/%s%s/v' -m '%s'", path, id, value);
  buffer[sizeof(buffer)-1] = '\0';
  system(buffer);
}

void settings_text(const char *path, const char *id, 
                   const char *name, const char *value)
{
  char buffer[1024];
  snprintf(buffer, sizeof(buffer)-1, 
          "mosquitto_pub -r -t 'settings/c/%s%s/t' -m text", path, id);
  buffer[sizeof(buffer)-1] = '\0';
  system(buffer);

  snprintf(buffer, sizeof(buffer)-1, 
          "mosquitto_pub -r -t 'settings/c/%s%s/n' -m '%s'", path, id, name);
  buffer[sizeof(buffer)-1] = '\0';
  system(buffer);
  
  settings_value(path, id, value);
}

void settings_group(const char *path, const char *id, const char *name)
{
  char buffer[1024];
  snprintf(buffer, sizeof(buffer)-1, 
          "mosquitto_pub -r -t 'settings/c/%s%s/t' -m group", path, id);
  buffer[sizeof(buffer)-1] = '\0';
  system(buffer);

  snprintf(buffer, sizeof(buffer)-1, 
          "mosquitto_pub -r -t 'settings/c/%s%s/n' -m '%s'", path, id, name);
  buffer[sizeof(buffer)-1] = '\0';
  system(buffer);
}


#define SETTINGS_START "dcf77"
#define SETTINGS_PATH  SETTINGS_START "/c/"
void settings_add(void)
{
  settings_group("", SETTINGS_START, "DCF77 Radio Clock");
  settings_text(SETTINGS_PATH, "time",   "Last Received Time", "---");
  settings_text(SETTINGS_PATH, "sym",    "Symbols Okay / Erroneous [Current]", 
                "0 / 0");
  settings_text(SETTINGS_PATH, "frames", "Frames Okay / Erroneous", "0 / 0");
}

void dcf_unify_time(struct timeval *e)
{
	if(e->tv_usec < 0)
	{
		e->tv_usec += 1000000;
		e->tv_sec--;
	}
	else if(e->tv_usec >= 1000000)
	{
		e->tv_usec -= 1000000;
		e->tv_sec ++;
	}
}

void dcf_sub_time(struct timeval *e, struct timeval *a, struct timeval *b)
{
	e->tv_sec = a->tv_sec - b->tv_sec;
	e->tv_usec = a->tv_usec - b->tv_usec;
	dcf_unify_time(e);
}

void dcf_add_time(struct timeval *e, struct timeval *a, struct timeval *b)
{
	e->tv_sec = a->tv_sec + b->tv_sec;
	e->tv_usec = a->tv_usec + b->tv_usec;
	dcf_unify_time(e);
}

int dcf_sub_abs_time(struct timeval *e, struct timeval *a, struct timeval *b)
{
	dcf_sub_time(e, a, b);
	if(e->tv_sec>=0) return 0;
	dcf_sub_time(e, b, a);
	return 1;
}

int dcf_test_parity(int *von, int *bis)
{
	int par = 1;
	while(von<bis) par ^= *von++;
	return par;
}

#define COUNT(X) (sizeof(X)/sizeof(*(X)))
long frames_okay = 0, frames_erroneous = 0;
long symbols_okay = 0, symbols_erroneous = 0;
void dcf_auswert(struct timeval *unixt, int *bit)
{
	static int zl[] = {21, 4, 3, 1, 4, 2, 1, 4, 2, 3, 4, 1, 4, 4, 1};
	static int zb[] = { 0, 1, 1, 0, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 0};
	int ziff[COUNT(zl)];
	int i, z, j, k;
	int wday, sign;
	struct tm tm;
	struct timeval dcft, delta;
	char date_buf[200];
	static struct extrabits
	{
		int bit;
		char *name;
	}
	extrabits[] = 
	{
	{15, "Reserveantenne"},
	{16, "Zeitumstellung"},
	{18, "Zeitzone"},
	{19, "Schaltsekunde"}
	};
	
	do
	{
		if(!(~bit[0] & bit[20] & 1
			 && dcf_test_parity(bit+21,  bit+29)
			 && dcf_test_parity(bit+29, bit+36)
                     && dcf_test_parity(bit+36, bit+59))) {
                  if(deb&D_ALLBITS) printf("parity test FAILED\n");
                  if (publish_settings) {
                    settings_value(SETTINGS_PATH, "time", "PARITY ERROR");
                  }
                  frames_erroneous++;
                  break;
                }
                frames_okay++;
		for(j=0, i=0; i<COUNT(zl); i++)
		{
			for(z=0, k=0; k<zl[i]; j++, k++)
			{
				z += (bit[j] & 1)<<k;
				if(deb&D_ALLBITS) printf("%d", bit[j]);
			}
			ziff[i] = z;
			if(deb&D_ALLBITS) if(zb[i]) printf("\t%d", z);
			if(deb&D_ALLBITS) printf("\n");
		}
		tm.tm_sec   = 0;
		tm.tm_min   = ziff[2] * 10 + ziff[1];
		tm.tm_hour  = ziff[5] * 10 + ziff[4];
		tm.tm_mday  = ziff[8] * 10 + ziff[7];
		tm.tm_mon   = ziff[11] * 10 + ziff[10] - 1;
		tm.tm_year  = ziff[13] * 10 + ziff[12];
                if (tm.tm_year < 80)
                  tm.tm_year += 100;
		tm.tm_isdst = bit[17]&1? 1: -1;
		wday = ziff[9];
		dcft.tv_sec = mktime(&tm);
		dcft.tv_usec = 0;
		if((time_t)-1 == dcft.tv_sec)
		{
			perror("mktime");
			break;
		}
		if(tm.tm_wday==0? wday!=7: wday!=tm.tm_wday)
		{
                  if (deb&D_EDGE)
                    printf("day of week mismatch, tm:%d, dcf:%d\n",
                           tm.tm_wday, wday);
                  break;
		}
		sign = dcf_sub_abs_time(&delta, &dcft, unixt);
                if (deb&D_EDGE)
                  printf("%c%ld.%06ld ", sign? '-': '+', delta.tv_sec, delta.tv_usec);
		strftime(date_buf, 100, "%a %H:%M %d.%m.%y %Z", &tm);
                strcat(date_buf, " [");
		for(j=0, i=0; i<COUNT(extrabits); i++)
                  if(bit[extrabits[i].bit] & 1) {
                    strcat(date_buf, j++? ",": "");
                    strcat(date_buf, extrabits[i].name);
                  }
                strcat(date_buf, "]");
                if (deb&D_EDGE)
                  printf("%s", date_buf);

                if (publish_settings) {
                  settings_value(SETTINGS_PATH, "time", date_buf);
                }

		if(setunix)
		{
			if((setunix&2) || (setunix&4) || delta.tv_sec > 2 * 60)
			{
				struct timeval newtime;
                                /* if (delta.tv_sec > 2 * 60) */
                                if (deb&D_EDGE)
                                  fprintf(stderr, 
                                          "dcf: clock off by more than 2 "
                                          "minutes, "
                                          "using settimeofday\n");
				usleep(1000);
				gettimeofday(&newtime, NULL);
				dcf_sub_time(&newtime, &newtime, unixt);
				dcf_add_time(&newtime, &newtime, &dcft);
				settimeofday(&newtime, NULL);
				setunix &= ~2;
			}
			else
			{
				struct timex tx;
				if(delta.tv_sec > 0 || delta.tv_usec > 100000)
					tx.T_MODE = ADJ_OFFSET_SINGLESHOT;
				else
					tx.T_MODE = ADJ_OFFSET;
				tx.offset = delta.tv_sec*1000000+delta.tv_usec;
				if(sign) tx.offset = -tx.offset;
				if(adjtimex(&tx)<0) perror("adjtimex(ADJ_OFFSET...)");
                                if (deb&D_EDGE)
                                  printf(" offs=%ld, freq=%ld, st=%d, tol=%ld",
                                         tx.offset, tx.T_FREQ, tx.status, tx.tolerance);
				if(fp_data)
				{
					strftime(date_buf, 100, "%H:%M %d", &tm);
					fprintf(fp_data, "%ld %s%ld.%06ld %ld %s\n", dcft.tv_sec,
							sign? "-": "", delta.tv_sec, delta.tv_usec,
							tx.T_FREQ, date_buf);
					fflush(fp_data);
				}
			}
		}
                if (deb&D_EDGE)
                  printf("\n");
                if (deb&D_EDGE)
                  printf("Frames Okay: %d, Frames erroneous: %d\n",
                         frames_okay, frames_erroneous);
	} while(0);

        if (publish_settings) {
          char buf[256];
          snprintf(buf, sizeof(buf)-1, "%d / %d", 
                   frames_okay, frames_erroneous);
          buf[sizeof(buf)-1] = '\0';
          settings_value(SETTINGS_PATH, "frames", buf);
        }
	fflush(stdout);
}

void dcf_delta(struct timeval *t1, int bit)
{
	static int bits[61];
	static bitno = -1;
        static int initialized = 0;
	static struct timeval t2;
	struct timeval td;

        if (bitno > 61) {
          bitno = -1;
          symbols_erroneous++;
        }
	dcf_sub_time(&td, t1, &t2);
	t2 = *t1;
	if(td.tv_sec>2) {
          bitno = -1;
          if (initialized)
            symbols_erroneous++;
        } else {
		int tdl;
		tdl = td.tv_sec * 1000000 + td.tv_usec;
                if (deb&D_EDGE)
                  printf("tdl: %d\n", tdl);
		if (tdl>=900000 && tdl<=1050000) {
                  ;
                /* 2013-06-30 gc: a little bit more time for the first
                 *                bit after dcf_auswert().
                 *                dcf_auswert() may run for several
                 *                hundert milliseconds
                 */
                } else if (bitno == 0 && (tdl>=900000 && tdl<=1900000)) {
                       ;
		} else if (tdl>=1950000 && tdl<=2050000) {
			if(bitno==59) dcf_auswert(t1, bits);
			bitno = 0;
		} else {
                  bitno = -1;
                  symbols_erroneous++;
                }
	}
	
	if(deb&D_EDGE)
	{
		char buf[100];
		strftime(buf, 100, "%H:%M:%S", localtime(&t1->tv_sec));
		if(bitno>=0)
			printf("%s.%06ld %02d:%c\n", buf, t1->tv_usec, bitno, "01X"[bit]);
		else
			printf("%s.%06ld ??:%c\n", buf, t1->tv_usec, "01X"[bit]);
	}
	if (bit==2) {
          bitno = -1;
          symbols_erroneous++;
        } else {
          symbols_okay++;
        }
        if (publish_settings) {
          char buf[256];
          snprintf(buf, sizeof(buf)-1, "%d / %d [%c%c:%c]", 
                   symbols_okay, symbols_erroneous,
                   (bitno>=0?'0'+bitno/10:'?'), (bitno>=0?'0'+bitno%10:'?'),
                   "01X"[bit]);
          buf[sizeof(buf)-1] = '\0';
          settings_value(SETTINGS_PATH, "sym", buf);
        }

	if(bitno>=0) bits[bitno++] = bit;
        initialized = 1;
}

static inline int dcf_readbit(void)
{
#ifdef BODODEBUG
	int bit;
	
	bit = inb(port) >> portbit;
	if(deb&D_VERBOSE) printf("%d\t%d\n",bit,(bit & 1));
	return bit & 1;
#else	
	return (inb(port) >> portbit) & 1; 
#endif
}

void dcf_poll(void)
{
	int bit;
	struct timeval t0, t1, t2;
	if(ioperm(port, 1, 1))
		perror("ioperm"), exit(1);
	while(1)
	{
#ifdef BODODEBUG
		if (deb&D_DEBUG)
		{
			printf("DEBUG: while (dcf_readbit())\nstart...");
			fflush(stdout);
		}
#endif
		gettimeofday(&t0, NULL);
		while(dcf_readbit())
		{
			gettimeofday(&t0, NULL);
			usleep(POLL_DISTANCE);
		}
		gettimeofday(&t1, NULL);
#ifdef BODODEBUG
		if (deb&D_DEBUG)
		{
			printf("end\n");
			fflush(stdout);
		}
#endif

		dcf_add_time(&t1, &t0, &t1);
		t1.tv_usec >>= 1;
		if(t1.tv_sec&1) t1.tv_usec += 500000;
		t1.tv_sec >>= 1;

#ifdef BODODEBUG
		if (deb&D_DEBUG)
		{
			printf("DEBUG: while (!dcf_readbit())\nstart...");
			fflush(stdout);
		}
#endif
		gettimeofday(&t0, NULL);
		while(!dcf_readbit())
		{
			gettimeofday(&t0, NULL);
			usleep(POLL_DISTANCE);
		}
		gettimeofday(&t2, NULL);
#ifdef BODODEBUG
		if (deb&D_DEBUG)
		{
			printf("end\n");
			fflush(stdout);
		}
#endif

		dcf_add_time(&t2, &t0, &t2);
		t2.tv_usec >>= 1;
		if(t2.tv_sec&1) t2.tv_usec += 500000;
		t2.tv_sec >>= 1;

		dcf_sub_time(&t2, &t2, &t1);
		if(t2.tv_sec) bit=2;
		else if(t2.tv_usec>70000 && t2.tv_usec<130000) bit=0;
		else if(t2.tv_usec>170000 && t2.tv_usec<230000) bit=1;
		else bit=2;
		if(deb&D_EDGE) printf("%ld.%06ld ", t2.tv_sec, t2.tv_usec);
		dcf_delta(&t1, bit);
	}
}

void dcf_uart(void)
{
	int fd, bit;
	unsigned char c;
	struct timeval t;
	static struct timeval t0 = {0, 190};
	static struct timeval t1 = {0, 190};
	struct termios tio[1];

	fd = open(tty, O_RDONLY);
	if(fd<0)
	{
		perror("dcf: open");
		exit(1);
	}
	tio->c_iflag = 0;
	tio->c_oflag = 0;
	tio->c_cflag = CS8|CREAD|CLOCAL;
	tio->c_lflag = NOFLSH;
	tio->c_cc[VMIN] = 1;
	tio->c_cc[VTIME] = 0;
	cfsetospeed(tio, B50);
	tcsetattr(fd, TCSANOW, tio);
	while(1)
	{
		read(fd, &c, 1);
		gettimeofday(&t, NULL);
		bit = 2;
        /*
       50 Baud 8,N,1
       
       0  10    30    50    70    90   110   130   150   170   190  [ms]
       +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
       |  0  | B0  | B1  | B2  | B3  | B4  | B5  | B6  | B7  |  1  |
       +-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+
      100000000000000000000001111111111111111111111111111111111111111 > 0xf8
      100000000000000000000000000000011111111111111111111111111111111 > 0xf0
      100000000000000000000000000000000000000011111111111111111111111 > 0xe0
      100000000000000000000000000000000000000000000000000001111111111 > 0x00
		*/
		if(c==0xf8 || c==0xf0 || c==0xe0)
		{
			bit = 0;
			dcf_sub_time(&t, &t, &t0);
		}
		else if(c==0)
		{
			bit = 1;
			dcf_sub_time(&t, &t, &t1);
		} else {
                  if (deb&D_ALLBITS)
                    printf("received erroneous byte 0x%02x\n", c);
                  if (c==0x80) {
			bit = 1;
			dcf_sub_time(&t, &t, &t1);
                  }

                }
		dcf_delta(&t, bit);
	}
}

void usage(void)
{
	fprintf(stderr, "usage: %s [options]\n"
			" -s source        set DCF77 source to one of:\n"
			"  port:PORT[,BIT] use bit BIT at io address PORT\n"
			"  tty:TTY         use tty TTY\n"
			"  Default is -s port:0x201,4\n"
			" -d MASK          enable debugging\n"
			" -u               set unix clock\n"
			" -U               set unix clock once\n"
			" -S               set unix clock using settimeofday\n"
			" -p               publish settings to mosquitto\n"
			" -t TICK          set tick (1000000/HZ = normal)\n",
			command);
	exit(1);
}

int main(int argc, char **argv)
{
	int opt;
	command = argv[0];
	while((opt=getopt(argc, argv, "s:d:uUSt:p")) != -1)
		switch(opt)
		{
		case 's':
			if(1<=sscanf(optarg, "port:%i,%i", &port, &portbit))
				source = S_GAMEPORT;
			else if(1<=sscanf(optarg, "tty:%s", tty))
				source = S_TTY;
			else usage();
			break;
		case 'd':
			sscanf(optarg, "%i", &deb);
			break;
		case 'u':
			setunix |= 1;
			break;
		case 'U':
			setunix |= 2;
			break;
		case 'S':
			setunix |= 4;
			break;
		case 'p':
                        publish_settings = 1;
                        settings_add();
			break;
		case 't':
			sscanf(optarg, "%i", &tick);
			break;
		default:
			usage();
		}
	fp_data = fopen("/var/adm/dcf77.time", "a");
	if(!fp_data) fprintf(stderr, "cannot open time log file\n");
	if(tick)
	{
		struct timex tx;
		tx.T_MODE = ADJ_TICK;
		tx.tick = tick;
		if(adjtimex(&tx)<0) perror("adjtimex(ADJ_TICK)");
	}
	if(source == S_GAMEPORT) dcf_poll();
	else dcf_uart();
	return 0;
}
