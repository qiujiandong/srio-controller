#ifndef _HW_COMMON_H_
#define _HW_COMMON_H_

#define FEXT(reg, REG_FIELD) \
    (((reg) & REG_FIELD##_MASK) >> REG_FIELD##_SHIFT)

#define FINS(reg, REG_FIELD, val) \
    ((reg) = ((reg) & ~REG_FIELD##_MASK) \
      | (((val) << REG_FIELD##_SHIFT) & REG_FIELD##_MASK))

#define FMK(REG_FIELD, val) \
    (((val) << REG_FIELD##_SHIFT) & REG_FIELD##_MASK)
    
#endif