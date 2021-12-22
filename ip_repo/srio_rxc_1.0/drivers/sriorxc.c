#include <sriorxc.h>

void SrioRxcIntEnable()
{
    hSrioRxc->CSR = 1;
}

void SrioRxcGetDbInfo(u16* dbInfo)
{
    *dbInfo = FEXT(hSrioRxc->CSR, CURRENT_INFO);
}
