#ifndef _SRIORXC_HW_H_
#define _SRIORXC_HW_H_

#include <xil_types.h>
#include "hw_common.h"

typedef struct 
{
    volatile u32 CSR;
}SrioRxcObj;
typedef SrioRxcObj *SrioRxcHandle;

#define EN_MASK               (0x00000001)
#define EN_SHIFT              (0x00000000)

#define CURRENT_INFO_MASK     (0xFFFF0000)
#define CURRENT_INFO_SHIFT    (0x00000010)

#endif