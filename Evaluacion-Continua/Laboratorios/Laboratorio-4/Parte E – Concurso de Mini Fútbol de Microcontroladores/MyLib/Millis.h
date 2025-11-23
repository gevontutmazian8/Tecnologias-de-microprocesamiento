/*
 * Millis.h
 *
 * Created: 8/11/2025 20:55:54
 *  Author: David
 */ 


#ifndef MILLIS_H_
#define MILLIS_H_

#include <stdint.h>

void init_millis(void);
uint32_t micros(void);
uint32_t millis(void);

#endif /* MILLIS_H_ */