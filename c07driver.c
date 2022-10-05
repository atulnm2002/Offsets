//  Test driver for Untangle assignment.
//
// Invocation:  ./c07 DATAFORMAT [-repeat]
//
//   DATAFORMAT is one of:
//      -clear      generate a clear-text test case
//      -encrypt    generate an encrypted test case, where the encryption
//                  method is described in the project specification
//
//   If the -repeat switch is omitted, the driver will choose a random 
//   quotation, and create a test case from that, and save the random seed
//   in a file named seed.txt; if the -repeat switch is present, the driver
//   will open the previously-created seed file and choose the same
//   quotation that was used previously to generate a test case.
//
//   Either way, a summary of the results of the testing will be written
//   to a file named c07Log_clear.txt or c07Log_encrypted.txt.
//
//   Writes a binary file containing the scrambled word records, as described 
//   in the specification; you can view the contents of that file by using:
//
//       hexdump -C Data.bin
//
// Library headers for various features:
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <time.h>
#include <stdint.h>
#include <inttypes.h>
#include <stdbool.h>

// "Local" headers for testing code and solution:
#include "Untangle.h"
#include "Generator.h"
#include "checkAnswer.h"

#define MAXWORDS 256       // maximum number of "words" in a quotation

/**  Write a formatted display of the word list to Out.
 * 
 *   Pre:  Out is opened for writing
 *         pWords points to an arra of nWords WordRecord objects
 */
void writeWordList(FILE* Out, const WordRecord* const pWords, uint8_t nWords);


int main(int argc, char** argv) {
   
   // Validate number of parameters:
   if ( argc != 2 && argc != 3 ) {
		printf("Invocation:  driver DATAFORMAT [-repeat]\n");
		printf("DATAFORMAT is -clear or -encrypt\n");
		exit(1);
	}
	
	// Variable for random seed:
   unsigned int Seed = 0;
   
	// Determine the mode of operation and set random seed:
	if ( argc == 3 && strcmp(argv[2], "-repeat") == 0 ) {
      FILE* fp = fopen("seed.txt", "r");
      if ( fp == NULL ) {
			printf("Could not open seed file... run without -repeat.\n");
			exit(2);
		}
      fscanf(fp, "%u", &Seed);
      fclose(fp);
	}
	else if ( argc == 3 ) {
		printf("Unrecognized option: %s\n", argv[1]);
		exit(3);
	}
	else {
      Seed = time(NULL);
      FILE* fp = fopen("seed.txt", "w");
      fprintf(fp, "%u\n", Seed);
      fclose(fp);
	}

   // Determine whether to generate clear-text or encrypted input data,
   // and set name for log and hexdump files:
   DataFormat Fmt;
   char* logFileName = NULL;
   char* binFileName = NULL;
   if ( strcmp(argv[1], "-clear") == 0 ) {
      Fmt = CLEAR;
      logFileName = "c07Log_clear.txt";
      binFileName = "data_clear.bin";
   }
   else if ( strcmp(argv[1], "-encrypt") == 0 ) {
      Fmt = ENCRYPTED;
      logFileName = "c07Log_encrypted.txt";
      binFileName = "data_encrypted.bin";
	}
	else {
		printf("Unrecognized data format option: %s\n", argv[1]);
		exit(3);
	}
   
   // Set pointer used as "handle" on memory region; the actual memory
   // region will be created later:
   uint8_t* pBuffer = NULL;
	
	// Generate test data; this allocates and initializes the memory region
	// (pointed to by pBuffer), and writes a copy of the memory region to a
	// file to make it easier to examine the contents:
	uint8_t maxWords = GenerateInput(Fmt, &pBuffer, binFileName, Seed);

   // Create array to hold the parsed word records:
   WordRecord* wordList = malloc(maxWords * sizeof(WordRecord) );	
   if ( wordList == NULL ) {
		printf("Failed to create data structure to hold results.\n");
		exit(1);
	}
	
	// Call Untangle() to parse the memory region pointed to by *pBuffer:
   uint8_t nWords = Untangle(Fmt, pBuffer, wordList);

   // Open log file for grading output:
   FILE* Log = fopen(logFileName, "w");
   if ( Log == NULL ) {
		printf("Could not open log file: %s\n", logFileName);
		exit(2);
	}
	
	// Write out word list to log file:
	fprintf(Log, "Here's your analysis:\n\n");
	writeWordList(Log, wordList, nWords);
	
	// Check word list against reference solution:
	fprintf(Log, "\nNow, we'll compare it to the reference solution...\n");
   uint16_t score = checkAnswer(Fmt, Log, pBuffer, wordList, nWords);
   
   // Write score to log file:
   fprintf(Log, "\nScore: %"PRIu16" / 1000\n", score);
   fclose(Log);
   
   // Clean up allocations:
   free( pBuffer );
   clearWordRecords(wordList, nWords);
   
   return 0;
}

/**  Write a formatted display of the word list to Out.
 * 
 *   Pre:  Out is opened for writing
 *         pWords points to an array of nWords word records
 */
void writeWordList(FILE* Out, const WordRecord* const pWords, uint8_t nWords) {
	
	for (uint8_t idx = 0; idx < nWords; idx++) {
	   fprintf(Out, "  0x%04"PRIX16":  %s\n", pWords[idx].offset, pWords[idx].word);
	}
}



