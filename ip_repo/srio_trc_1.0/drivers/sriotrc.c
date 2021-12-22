#include "sriotrc.h"

void sendDB(
    u16 info
){
    hSrioTrc->INFOSIZE = FMK(INFOSIZE_INFO, info);
    hSrioTrc->START = FMK(START_DB, 1);
}

void sendSwrite(
    SrioSwSetup* swSetup
){
    hSrioTrc->SRCADDR = swSetup->srcAddr;
    hSrioTrc->DSTADDR = swSetup->dstAddr;
    hSrioTrc->INFOSIZE = FMK(INFOSIZE_INFO, swSetup->info) |
                         FMK(INFOSIZE_SIZE, swSetup->sizeInDw);
    hSrioTrc->START = FMK(START_SW, 1);
}