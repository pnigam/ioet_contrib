#define LED_SYMBOLS \
	{ LSTRKEY("led_init"), LFUNCVAL(led_init)}, \

#define MAX_COLOR_VALUE 31
#define MIN_COLOR_VALUE 0
#define REG_GPERS 0x400E1004
#define REG_ODERS 0x400E1044
#define REG_OVRS 0x400E1054
#define REG_OVRC 0x400E1058

static const int gpiopinmap [] = {
    0x0109, //D0 = PB09
    0x010A, //D1 = PB10
    0x0010, //D2 = PA16
    0x000C, //D3 = PA12
    0x0209, //D4 = PC09
    0x000A, //D5 = PA10
    0x000B, //D6 = PA11
    0x0013, //D7 = PA19
    0x000D, //D8 = PA13
    0x010B, //D9 = PB11
    0x010C, //D10 = PB12
    0x010F, //D11 = PB15
    0x010E, //D12 = PB14
    0x010D, //D13 = PB13
};

int display(lua_State *L);
int set(lua_State *L);
int set_all(lua_State *L);

struct led_strip
{
 int nled; //total number of leds
 uint16_t * rgbpixel; //array of led RGB values
 uint32_t dpin; //data pin
 uint32_t dport; //data port
 uint32_t cpin; //clock pin
 uint32_t cport; //clock port
};

static const LUA_REG_TYPE led_meta_map[] =
{
 { LSTRKEY("display"), LFUNCVAL (display)},
 { LSTRKEY("set"), LFUNCVAL (set)},
 { LSTRKEY("setAll"), LFUNCVAL (set_all)},
 { LSTRKEY( "__index"), LROVAL ( led_meta_map)},
 {LNILKEY, LNILVAL},
};

/*
Function call: object = storm.n.led_init(number of leds, data pin, clock pin)
number of leds: integer
data pin: storm.io.{D2-D13}
clock pin: storm.io.{D2-D13}
returns object of type struct led_strip
*/
int led_init(lua_State *L)
{
 struct led_strip * led = lua_newuserdata(L, sizeof(struct led_strip));  

 led->nled = (int)malloc(sizeof(int));
 int temp = lua_tonumber(L, 1);
 memcpy(&(led->nled), &temp, sizeof(int));
 
 led->rgbpixel = (uint16_t *)malloc(temp*sizeof(uint16_t));
 memset(led->rgbpixel, 0, temp*sizeof(uint16_t)); 

 temp = lua_tonumber(L,2);
 uint32_t par = gpiopinmap[temp] % 32;
 memcpy(&(led->dpin), &par, sizeof(int));
 par = (gpiopinmap[temp] & 0xF00) >> 8;
 memcpy(&(led->dport), &par, sizeof(int));
 
 temp = lua_tonumber(L,3);
 par = gpiopinmap[temp] % 32;
 memcpy(&(led->cpin), &par, sizeof(int));
 par = (gpiopinmap[temp] & 0xF00) >> 8;
 memcpy(&(led->cport), &par, sizeof(int));
  
 //set them as output pins
 lua_pushlightfunction(L, libstorm_io_set_mode);
 lua_pushnumber(L,0);
 lua_pushnumber(L, led->dpin);
 lua_pushnumber(L, led->cpin);
 lua_call(L, 3, 0);

 lua_pushrotable (L, (void *) led_meta_map);
 lua_setmetatable(L, -2);
 return 1;
}

/*
Function call: display()
Displays the values set in rgbpixel array in struct led_strip
*/
int display(lua_State *L)
{
    struct led_strip *led = lua_touserdata(L,1);
    uint32_t dportmask = (led->dport * 2) << 8;    
    uint32_t cportmask = (led->cport * 2) << 8;

    //Setup data and clock pins as output pins
	uint32_t volatile *data_gpio = (uint32_t *) (REG_GPERS | dportmask);
	*data_gpio = 1 << led->dpin;
	uint32_t volatile *clock_gpio = (uint32_t *) (REG_GPERS | cportmask);
	*clock_gpio = 1 << led->cpin;

	uint32_t volatile *data_oder = (uint32_t *) (REG_ODERS | dportmask);
	*data_oder = 1 << led->dpin;
	uint32_t volatile *clock_oder = (uint32_t *) (REG_ODERS | cportmask);
	*clock_oder = 1 << led->cpin;

    //Data and clock pin set and clear registers
	uint32_t volatile *data_ovrs = (uint32_t *) (REG_OVRS | dportmask);
    uint32_t volatile *data_ovrc = (uint32_t *) (REG_OVRC | dportmask);
	uint32_t volatile *clock_ovrs = (uint32_t *) (REG_OVRS | cportmask);
    uint32_t volatile *clock_ovrc = (uint32_t *) (REG_OVRC | cportmask);

    //Set data pin to low
    *data_ovrc = 1 << led->dpin;
    //Toggle clock pin 32 times
    int i,j;
    for (i=0; i<32; i++) {
        *clock_ovrs = 1 << led->cpin;
        *clock_ovrc = 1 << led->cpin;
    }
    
    // Iterate over all leds
    for(i=0;i<led->nled;i++)
    {
        //Output 1 as start bit
        *data_ovrs = 1 << led->dpin;
        *clock_ovrs = 1 << led->cpin;
        *clock_ovrc = 1 << led->cpin;

        uint16_t this_color= led->rgbpixel[i];
        for(j=0x4000; j; j >>= 1)
        {	
    		if(this_color & j)
    		{
                *data_ovrs = 1 << led->dpin;
    		}
	        else
	    	{
                *data_ovrc = 1 << led->dpin;
	    	}
            *clock_ovrs = 1 << led->cpin;
            *clock_ovrc = 1 << led->cpin;
	    }
    }
        
    //nled pulse
    *data_ovrc = 1 << led->dpin;
    for (i=0; i<led->nled; i++) {
        *clock_ovrs = 1 << led->cpin;
        *clock_ovrc = 1 << led->cpin;
    }
    return 0;
}

/*
Function call: set(index, r, g, b)
index: integer between 0 and number of leds - 1
r, g, b: integer between 0 and MAX_COLOR_VALUE
Upon successful call, function sets required value in specified index of rgbpixel. To see set value, call display().
*/
int set(lua_State *L)
{
	struct led_strip *led = lua_touserdata(L,1);
	int index = lua_tonumber(L, 2);
	uint16_t r = (uint16_t)lua_tonumber(L,3); 
	uint16_t g = (uint16_t)lua_tonumber(L,4); 
	uint16_t b = (uint16_t)lua_tonumber(L,5); 

    if((r>MAX_COLOR_VALUE) || (g>MAX_COLOR_VALUE) || (b>MAX_COLOR_VALUE) || (r<MIN_COLOR_VALUE) || (g<MIN_COLOR_VALUE) || (b<MIN_COLOR_VALUE))
	{
		printf("RGB values out of range\n");
		return 0;
	}
    if(index >= led->nled || index < 0) {
        printf("Index value out of range\n");
		return 0;
    }
    r=r & 0x1F;
    g=g & 0x1F;
    b=b & 0x1F;
    uint16_t data = (b << 10) | (r << 5) | g;
	led->rgbpixel[index] = data;
	return 0;
}

/*
Function call: setAll(r, g, b)
r, g, b: integer between 0 and MAX_COLOR_VALUE
Upon successful call, function sets required value in all indices of rgbpixel. To see set value, call display().
*/
int set_all(lua_State *L) {
	struct led_strip *led = lua_touserdata(L,1);
	uint16_t r = (uint16_t)lua_tonumber(L,2); 
	uint16_t g = (uint16_t)lua_tonumber(L,3); 
	uint16_t b = (uint16_t)lua_tonumber(L,4);
    if((r>MAX_COLOR_VALUE) || (g>MAX_COLOR_VALUE) || (b>MAX_COLOR_VALUE) || (r<MIN_COLOR_VALUE) || (g<MIN_COLOR_VALUE) || (b<MIN_COLOR_VALUE))
	{
		printf("RGB values out of range\n");
		return 0;
	}
    r=r & 0x1F;
    g=g & 0x1F;
    b=b & 0x1F;
    uint16_t data = (b << 10) | (r << 5) | g;
    int i;
    for(i=0; i < led->nled; i++) {
    	led->rgbpixel[i] = data;
    }
    return 0;
}
