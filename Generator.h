// Generator.h
//
// !! DO NOT MODIFY THIS FILE IN ANY WAY !!
//
#ifndef GENERATOR_H
#define GENERATOR_H
#include <inttypes.h>
#include "Untangle.h"    // for DataFormat

/**  Generates input data for Untangle().
 * 
 *   Pre:   Fmt == CLEAR or ENCRYPTED
 *          pBuffer points to the caller's pointer
 *          genFileName is the name for the file containing test data
 *   Post:  *pBuffer points to the memory region holding test data
 *          A copy of the test data is written to the specified file
 *   Returns:  an upper bound on the number of "words" in the given test;
 *                there may actually be fewer than that (so be careful!)
 */
uint8_t GenerateInput(DataFormat Fmt, uint8_t** pBuffer, char* genFileName, uint32_t Seed);

#endif


