/*
 * adc_module.c
 *
 *  Created on: Sep 16, 2016
 *      Author: tweathe1
 */

// Configuration of the ADC

#include <stdbool.h>
#include <stdint.h>
#include "inc/hw_memmap.h"
#include "driverlib/adc.h"
#include "driverlib/gpio.h"
#include "driverlib/pin_map.h"
#include "driverlib/sysctl.h"

void init_ADC(void)
{
    //
    // The ADC0 peripheral must be enabled for use.
    //
    SysCtlPeripheralEnable(SYSCTL_PERIPH_ADC0);

    //
    // For this, ADC0 is used with AIN1 on port E2.
    // The actual port and pins used may be different on your part, consult
    // the data sheet for more information.  GPIO port E needs to be enabled
    // so these pins can be used.
    //
    SysCtlPeripheralEnable(SYSCTL_PERIPH_GPIOE);

    //
    // Select the analog ADC function for these pins.
    // Consult the data sheet to see which functions are allocated per pin.
    //
    GPIOPinTypeADC(GPIO_PORTE_BASE, GPIO_PIN_5);

    //
    // Enable sample sequence 3 with a processor signal trigger priority 0 (highest).
    // Sequence 3 will do 1 sample when the processor sends a signal to start the
    // conversion.  Each ADC module has 4 programmable sequences, sequence 0
    // to sequence 3.
    //
    ADCSequenceConfigure(ADC0_BASE, 3, ADC_TRIGGER_PROCESSOR, 0);

    //
    // Configure step 0 on sequence 3.  Sample channel 8 (ADC_CTL_CH8)
    // in single-ended mode (default) and configure the interrupt flag
    // (ADC_CTL_IE) to be set when the sample is done.  Tell the ADC logic
    // that this is the last conversion on sequence 3 (ADC_CTL_END).
    // Sequence 1 and 2 have 4 steps, and sequence 0 has 8 programmable steps.
    // Since we are only doing a single conversion using sequence 3 we will only
    // configure step 0. For more information on the ADC sequences and steps, reference the datasheet.
	// Chose to use Port E Pin 5 (PE5). This corresponds to Ain8 so use channel 8.
    //
    ADCSequenceStepConfigure(ADC0_BASE, 3, 0, (ADC_CTL_CH8 | ADC_CTL_IE |
                             ADC_CTL_END));

    //
    // Since sample sequence 3 is now configured, it must be enabled.
    //
    ADCSequenceEnable(ADC0_BASE, 3);

    //
    // Clear the interrupt status flag.  This is done to make sure the
    // interrupt flag is cleared before we sample.
    //
    ADCIntClear(ADC0_BASE, 3);

}

uint16_t ReadADC(void) {
    uint32_t buffer[1];	// Buffer size (FIFO) of sequencer 3 is only 1 sample

    // Must tell it to start triggering to be able to get the data
    ADCProcessorTrigger(ADC0_BASE, 3);

    // Wait until the interrupt is set that tells it has a value to read
    while(!ADCIntStatus(ADC0_BASE, 3, false))
    {

    }

    // Clear the interrupt
    ADCIntClear(ADC0_BASE, 3);

    // Get the value
    ADCSequenceDataGet(ADC0_BASE, 3, &buffer[0]);

    return buffer[0];
}
