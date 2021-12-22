#ifndef _SRIORXC_H_
#define _SRIORXC_H_

#include <sriorxc_hw.h>
#include <xparameters.h>

#define hSrioRxc ((SrioRxcObj*)XPAR_HIER_SRIO_SRIO_RXC_0_BASEADDR)

void SrioRxcIntEnable();
void SrioRxcGetDbInfo(u16 *dbInfo);

#endif