// Configure UART

#include <stdint.h>
#include <stdbool.h>
#include <stdio.h>
#include "inc/hw_memmap.h"
#include "driverlib/gpio.h"
#include "driverlib/pin_map.h"
#include "driverlib/sysctl.h"
#include "driverlib/uart.h"
#include "utils/uartstdio.h"

void init_UART(void)
{
	//
	// Enable GPIO port A which is used for UART0 pins.
	//
	SysCtlPeripheralEnable(SYSCTL_PERIPH_GPIOA);

	//
	// Configure the pin muxing for UART0 functions on port A0 and A1.
	// This step is not necessary if your part does not support pin muxing.
	//
	GPIOPinConfigure(GPIO_PA0_U0RX);
	GPIOPinConfigure(GPIO_PA1_U0TX);

	//
	// Enable UART0 so that we can configure the clock.
	//
	SysCtlPeripheralEnable(SYSCTL_PERIPH_UART0);

	//
	// Select the alternate (UART) function for these pins.
	//
	GPIOPinTypeUART(GPIO_PORTA_BASE, GPIO_PIN_0 | GPIO_PIN_1);

	UARTConfigSetExpClk(UART0_BASE, SysCtlClockGet(), 9600,
	         (UART_CONFIG_WLEN_8 | UART_CONFIG_STOP_ONE |
	         UART_CONFIG_PAR_NONE));
}
