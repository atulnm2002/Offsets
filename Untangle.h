// Untangle.h
//
// !! DO NOT MODIFY THIS FILE IN ANY WAY !!
//
#ifndef UNTANGLE_H
#define UNTANGLE_H
#include <stdio.h>
#include <stdint.h>

enum _DataFormat {CLEAR, ENCRYPTED};
typedef enum _DataFormat DataFormat;

struct _WordRecord {
	uint16_t offset;    // offset at which word record was found in memory
	char*    word;      // dynamically alloc'd C-string containing the "word"
};
typedef struct _WordRecord WordRecord;

/**
 *  Untangle() parses a chain of records stored in the memory region pointed
 *  to by pBuffer, and stores WordRecord objects representing the given data
 *  into the array supplied by the caller.
 * 
 *  Pre:    Fmt == CLEAR or ENCRYPTED
 *          pBuffer points to a region of memory formatted as specified
 *          wordList points to an empty array large enough to hold all the
 *             WordRecord objects you'll need to create
 *  Post:   wordList[0:nWords-1] hold WordRecord objects, where nWords is
 *             is the value returned by Untangle()
 *  Returns: the number of "words" found in the supplied quotation.
 */
uint8_t Untangle(DataFormat Fmt, const uint8_t* pBuffer, WordRecord* const wordList);

/**
 *  Deallocates an array of WordRecord objects.
 * 
 *  Pre:    wordList points to a dynamically-allocated array holding nWords
 *             WordRecord objects
 *  Post:   all dynamic memory related to the array has been freed
 */
void clearWordRecords(WordRecord* const wordList, uint8_t nWords);
 
#endif


