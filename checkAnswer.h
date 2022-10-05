// checkAnswer.h
//
// !! DO NOT MODIFY THIS FILE IN ANY WAY !!
//
#ifndef CHECKANSWER_H
#define CHECKANSWER_H
#include <stdio.h>
#include <inttypes.h>
#include "Untangle.h"

/**  Checks/grades word record list parsed from *pBuffer.
 * 
 *   Pre:   Fmt == CLEAR or ENCRYPTED
 *          Out is open for writing
 *          pBuffer points to a memory region as described in the specification
 *          wordist points to an array of nWords WordRecord objects
 *   Post:  *Out contains detailed grading information
 *   Returns:  the overall score (max is 1000)
 */
uint16_t checkAnswer(DataFormat Fmt, FILE* Out, const uint8_t* pBuffer, const WordRecord* wordList, uint8_t nWords);

#endif
