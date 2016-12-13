/*
 * main.c
 */

#include <stdint.h>
#include <math.h>
#include <stdio.h>
#include <string.h>
#include <stdbool.h>

#include "inc/hw_types.h"
#include "inc/hw_memmap.h"
#include "driverlib/adc.h"
#include "driverlib/sysctl.h"
#include "driverlib/uart.h"
#include "inc/tm4c123gh6pm.h"
#include "driverlib/pin_map.h"

void init_ADC(void);
void init_UART(void);
uint16_t ReadADC(void);

int main(void) {

    uint16_t adcData;
    int i = 0;
    char strToSend[4] = "";	// Will only send 1 value at a time

	SysCtlClockSet( SYSCTL_USE_PLL | SYSCTL_OSC_MAIN | SYSCTL_XTAL_16MHZ | SYSCTL_SYSDIV_4 );
	init_ADC();
	init_UART();

	while(1)
	{
		adcData = ReadADC();

		sprintf(strToSend, "%d\n\r", adcData);

		for(i = 0; strToSend[i] != '\0'; i++)
			UARTCharPut(UART0_BASE,strToSend[i]);

	}

	return(0);
}
