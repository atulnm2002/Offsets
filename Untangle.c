#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "Untangle.h"


// On my honor:
//
// - I have not discussed the C language code in my program with
// anyone other than my instructor or the teaching assistants
// assigned to this course.
//
// - I have not used C language code obtained from another student,
// the Internet, or any other unauthorized source, either modified
// or unmodified.
//
// - If any C language code or documentation used in my program
// was obtained from an authorized source, such as a text book or
// course notes, that has been clearly noted with a proper citation
// in the comments of my program.
//
// - I have not designed this program in such a way as to defeat or
// interfere with the normal operation of the Curator System.
//
// <Atul Bharadwaj>
// <atulnm2002>


uint8_t Untangle(DataFormat Fmt, const uint8_t* pBuffer, WordRecord* const wordlist)
{
    uint8_t nWords = 0;
    if (Fmt == CLEAR)
    {
        uint16_t offset = *((uint16_t*)pBuffer);
        while(offset != 0)
        {
            uint8_t length = *(pBuffer + offset);
            WordRecord record;
            length = length - 2; //for the terminator
            record.word = calloc(length, sizeof(char));
            memcpy(record.word, (pBuffer + offset + 3), length - 1);

            record.offset = offset + 3;
            offset = *((uint16_t*)(pBuffer + offset + 1));
            
            wordlist[nWords] = record;
            nWords++;
        }
    }
    else if (Fmt == ENCRYPTED)
    {
        uint16_t offset = *((uint16_t*)pBuffer);
        while(offset != 0)
        {
            uint8_t length = *((uint8_t*)(pBuffer + offset));
            WordRecord record;
            uint16_t noffset = *((uint16_t*)(pBuffer + offset + 1));
            length = length - 2;
            record.word = calloc (length, sizeof(char));
            uint8_t nlength = length - 1;
            uint8_t mask = 0;
            uint16_t omask = 0;

            //still need to flip mask
            for (int i = 0; i < 8; i++)
            {
                mask = (mask << 1)|(nlength & 1);
                nlength = nlength >> 1;
            }
            memcpy(record.word, (pBuffer + offset + 3), length - 1);
            for (int i = 0; i < length - 1; i++)
            {
                //need to copy each letter which is xored
                record.word[i] = record.word[i] ^ mask;
            }
            omask = (uint16_t)record.word[0];
            omask = (omask << 8) | omask;
            noffset = noffset ^ omask;
            record.offset = offset + 3;
            wordlist[nWords] = record;
            nWords++;
            offset = noffset;
        }
    }
    return nWords;

}

void clearWordRecords(WordRecord* const wordList, uint8_t nWords)
{
    if(wordList == NULL)
    {
        exit(0);
    }
    else
    {
        for(int i = 0; i < nWords; i++)
        {
            free(wordList[i].word);
            
        }
        free( wordList);
    }
}