
#include "type.h"

#define COLOR	0x002e	


void __disp_str(u8_t * string, u32_t  color);
void __disp_clock(u8_t * string, u32_t  color);
void __init8259(); 
int hz = 0;
int clock = 500;

int _inc_clock(){
char * time = "00:00:00\0";
int temp;
int seconds;
int min;
int hour;

	hz++; 
	if (hz >= 18){
		hz = 0;
		clock++;
		time[7] =(char) ((clock % 60) - 208);
		min = (clock / 60) % 60;
		hour = clock / 3600;
		seconds = clock - (min * 60);
		int temp = seconds / 10;
		time[6] = (char) ((temp ) -208);
		time[7] = (char) ((seconds - temp *10 ) -208);
		temp = min / 10;
		time[3] = (char) ((temp ) -208);
		time[4] = (char) ((min - temp *10 ) -208);
		temp = hour / 10;
		time[0] = (char) ((temp ) -208);
		time[1] = (char) ((hour - (temp *10)) -208);
		
		__disp_clock(time,COLOR);
		
		
	}
return 0;
}

int _begin (u32_t ver)  {

	__disp_str("Press a key to start ...", COLOR);
	__disp_str("\n ", COLOR);
	__disp_clock("00:00:00",COLOR);
	__init8259();
	
	return 0;
}
