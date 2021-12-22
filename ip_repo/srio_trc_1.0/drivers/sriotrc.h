#ifndef _SRIOTRC_H_
#define _SRIOTRC_H_

#include "sriotrc_hw.h"
#include <xparameters.h>

#define hSrioTrc ((SrioTrcObj*)XPAR_HIER_SRIO_SRIO_TRC_0_BASEADDR)

typedef struct 
{
    u32 srcAddr;
    u32 dstAddr;
    u16 sizeInDw;
    u16 info;
}SrioSwSetup;


void sendDB(
    u16 info);

void sendSwrite(
    SrioSwSetup* swSetup);

#endif