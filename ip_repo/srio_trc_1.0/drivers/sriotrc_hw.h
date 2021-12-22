#ifndef _SRIOTRC_HW_H_
#define _SRIOTRC_HW_H_

#include <xil_types.h>
#include "hw_common.h"

typedef struct 
{
    volatile u32 START;
    volatile u32 SRCADDR;
    volatile u32 DSTADDR;
    volatile u32 INFOSIZE;
} SrioTrcObj;

typedef SrioTrcObj *SrioTrcHandle;

#define START_DB_MASK        (0x00000001)
#define START_DB_SHIFT       (0x00000000)

#define START_SW_MASK        (0x00000002)
#define START_SW_SHIFT       (0x00000001)

#define START_NR_MASK        (0x00000004)
#define START_NR_SHIFT       (0x00000002)

#define INFOSIZE_INFO_MASK   (0xFFFF0000)
#define INFOSIZE_INFO_SHIFT   (0x00000010)

#define INFOSIZE_SIZE_MASK   (0x0000FFFF)
#define INFOSIZE_SIZE_SHIFT   (0x00000000)

#endif
