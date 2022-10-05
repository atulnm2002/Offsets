#! /bin/bash
#
#  Last modified:  April 6, 2022
#
#  This script must be executed in a directory that contains the grading harness
#  tar file (c07Grader.tar) posted on the course website; that tar file must
#  contain the files:
#
#    c07driver.c
#    Untangle.h
#    Generator.h
#    Generator.o
#    checkAnswer.h
#    checkAnswer.o
#
#  The directory must also contain your completed Untangle.c file; we recommend
#  that you name that file yourPID.c, using your VT email PID as the first part
#  of the file name (e.g., wmcquain.c).
#
#  Invocation:  ./gradeC07.sh <name of your .c file>
#               e.g., ./gradeC07.sh wmcquain.c
#
#  Various text files are created, and contain portions of the test results.
#  Overall results can be found in a file named PID.txt, if you followed the 
#  suggested naming convention for your C source file.
#
#  Alternate invocation:  ./gradeC07.sh -clean
#
#  This will remove the files created by an earlier run of the grading script;
#  it's useful if you just want to start with a pristine environment.
#
#  Name of grading package file:
gradingTar="c07Grader.tar"

#  Rename for student file; student's source file is copied to the build 
#  directory and renamed as follows:
renameC="Untangle.c"

#  Names for directories
buildDir="build"

#   Names for log files created by this script:
headerLog="header.txt"            # boilerplate and timestamp for test
buildLog="buildLog.txt"           # messages related to build process
testLog="testLog.txt"             # messages related to running the tests
resultsLog="testResults.txt"      # test data and log output from running tests
vgrindLog="vgrindLog.txt"         # verbose Valgrind output
vgrindIssues="vgrind_issues.txt"  # summary of errors reported by Valgrind
seedFile="seed.txt"               # holds random seed for data generation

#   Temp name for the executable; reset in build section
exeName="driver"
exeSuffix="_c07"

#   Names for driver output logs and memory region (binary) files
clearLog="c07Log_clear.txt"
clearDmp="data_clear.bin"
encryptLog="c07Log_encrypted.txt"
encryptDmp="data_encrypted.bin"

#  Names for driver-generated test results file
scoreFile="c07scores.txt"

#   Delimiter to separate sections of report file:
Separator="============================================================"

############################################################## cleaning fn
#  Remove files created during test;
#   Names for log files created by this script:
clean() {
   rm -Rf $seedFile
   rm -Rf *.txt ./$buildDir *$exeSuffix
   #exit 0
}

############################################# fn to check for tar file
#                 param1:  name of file to be checked
isTar() {

   mimeType=`file -b --mime-type $1`
   if [[ $mimeType == "application/x-tar" ]]; then
     return 0
   fi
   if [[ $mimeType == "application/x-gzip" ]]; then
     return 0
   fi
   return 1
}

##################################### fn to extract token from file name
#                 param1: (possibly fully-qualified) name of file
#  Note:  in production use, the first part of the file name will be the
#         student's PID
#
getPID() { 

   fname=$1
   # strip off any leading path info
   fname=${fname##*/}
   # extract first token of file name
   sPID=${fname%%.*}
}

###################################### fn to compute late penalty
#                   param1:  PID of studentresultsFile
#  The penalty is based on the presence of an entry for the given PID
#  in the file specified by the config variable latePenaltyDataFile;
#  that file must be produced by the LateDaysCalculator.jar utility.
#
#  The amount of the penalty is determined by the config variable
#  perDiemPenalty (which must usually be reset based on the maximum
#  score for the assignment in question).
#
#  The penalty, if any, is logged to the file specified by the config
#  variable latePenaltyReport,
#
computeLatePenalty() {     

   if [[ -e $latePenaltyReport ]]; then
      rm -rf $latePenaltyReport
   fi
   
   targetPID=$1
   daysLate=0
   
   # see if there's a line corresponding to the given student
   studentLine=`grep $targetPID $latePenaltyDataFile`
   if [[ $? -eq 0 ]]; then
      prefix="*"$'\t'
      daysLate=${studentLine##$prefix}
      latePenalty=$(( daysLate * perDiemPenalty ))
      echo "Late penalty for this submission:"  > $latePenaltyReport
      echo >> $latePenaltyReport
      echo "Number of days late: $daysLate" >> $latePenaltyReport
      echo "Penalty (percentage): $latePenalty" >> $latePenaltyReport
   fi
}

############################################################ Validate command line

# Verify number of parameters
   if [[ $# -ne 1 ]]; then
      echo "You must specify the name of your C source file (or -clean)."
      exit 1
   fi
   
# See if user selected the cleaning option
  if [[ $1 == "-clean" ]]; then
     echo "Removing earlier test files..."
     clean
     exit 0
  fi

# Verify presence of named file
   sourceFile="$1"
   if [ ! -e $sourceFile ]; then
      echo "The file $sourceFile does not exist."
      exit 2
   fi
   
############################################################ Check for grading package

   if [[ ! -e $gradingTar ]]; then
      echo "$gradingTar is not present"
      exit 3
   fi
   
   isTar $gradingTar
   if [[ $? -ne 0 ]]; then
      echo "$gradingTar does not appear to be a tar file"
      exit 4
   fi

############################################################ Get student's PID
   
   # Extract first token of C file name (student PID when we run this)
   getPID $sourceFile
   
   # Initiate header for grading log
   echo "Grading:  $1" > $headerLog
   echo -n "Time:     " >> $headerLog
   echo `date` >> $headerLog
   echo >> $headerLog
   
############################################################ Prepare for build
  
   # Create log file:
   echo "Executing gradeC07.sh..." > $buildLog
   echo >> $buildLog
   
   # Create build directory:
   echo "Creating build subdirectory" >> $buildLog
   echo >> $buildLog
   # Create build directory if needed; empty it if it already exists
   if [[ -d $buildDir ]]; then
      rm -Rf ./$buildDir/*
   else
      mkdir $buildDir
   fi
   
   # Copy student's C file to the build directory
   echo "Copying student source file to the build directory:" >> $buildLog
   cp $sourceFile ./$buildDir/$renameC >> $buildLog
   echo >> $buildLog
   
   # Unpack the test source files into the build directory
   echo "Unpacking test code into build directory:" >> $buildLog
   tar xf $gradingTar -C ./$buildDir >> $buildLog

   # Move to build directory
   cd ./$buildDir
   
############################################################ Build the test driver

   #   Build command:
   exeName=$sPID"_c07"
   buildCMD="gcc -o $exeName -std=c11 -Wall -ggdb3 c07driver.c $renameC Generator.o checkAnswer.o"

   # build the driver; save output in build log
   echo "Compiling test code and submission" >> ../$buildLog
   $buildCMD >> ../$buildLog 2>&1
   echo >> ../$buildLog

   # Verify existence of executable
   if [[ ! -e $exeName ]]; then
      echo "Build failed; the file $exeName does not exist" >> ../$buildLog
      echo $Separator >> ../$buildLog
      mv ../$buildLog ../$sPID.txt
      exit 7
   fi
   if [[ ! -x $exeName ]]; then
      echo "Permissions error; the file $exeName is not executable" >> ../$buildLog
      echo $Separator >> ../$buildLog
      mv ../$buildLog ../$sPID.txt
      exit 8
   fi

   echo "Build succeeded..." >> ../$buildLog
   
   # Move executable up to test directory and return there
   echo "Moving the executable $exeName to the test directory." >> ../$buildLog
   mv ./$exeName ..
   cd ..

############################################################ Perform testing

   # Test first with -clear
   echo "Preparing to execute student solution with -clear..." > $testLog
   killed="no"
   timeout 30 $exeName -clear >> $testLog 2>&1
   timeoutStatus="$?"
   # echo "timeout said: $timeoutStatus"
   if [[ $timeoutStatus -eq 124 || $timeoutStatus -eq 137 ]]; then
      echo "The test of your solution timed out after 30 seconds." >> $testLog
   elif [[ $timeoutStatus -eq 134 ]]; then
      echo "The test of your solution was killed by a SIGABRT signal." >> $testLog
      echo "Possible reasons include:" >> $testLog
      echo "    - a segfault error" >> $testLog
      echo "    - a serious memory access error" >> $testLog
   fi
  
   # Check for existence of expected output files  and preserve them
   # (the succeeding Valgrind run will overwrite the first set):
   if [[ ! -e $clearDmp ]]; then
      # This should NEVER happen...
      echo "Error:  $clearDmp was not created!" >> $testLog
   else
      # write test info for -clear to summary log
      echo "Information about testing with -clear:" > $resultsLog
      echo -n "Seed value was: " >> $resultsLog
      cat $seedFile >> $resultsLog
      echo >> $resultsLog
      echo "Hexdump of memory region:" >> $resultsLog
      echo >> $resultsLog
      hexdump -C $clearDmp >> $resultsLog   
      echo >> $resultsLog
   fi
   if [[ ! -e $clearLog ]]; then
      echo "Error:  $clearLog was not created!" >> $testLog
   else
      echo "Your output log:" >> $resultsLog
      echo >> $resultsLog
      cat $clearLog >> $resultsLog
      echo >> $resultsLog
      echo $Separator >> $resultsLog
   fi

   # Because the test executes so quickly, we need to trigger a short
   # sleep to give the system clock time to update for the next test.
   sleep 1

   # Test second with -encrypted
   echo "Preparing to execute student solution with -encrypt..." >> $testLog
   timeout 30 $exeName -encrypt >> $testLog 2>&1
   if [[ $timeoutStatus -eq 124 || $timeoutStatus -eq 137 ]]; then
      echo "The test of your solution timed out after 30 seconds." >> $testLog
   elif [[ $timeoutStatus -eq 134 ]]; then
      echo "The test of your solution was killed by a SIGABRT signal." >> $testLog
      echo "Possible reasons include:" >> $testLog
      echo "    - a segfault error" >> $testLog
      echo "    - a serious memory access error" >> $testLog
   fi
  
   # Check for existence of expected output files:
   if [[ ! -e $encryptDmp ]]; then
      echo "Error:  $encryptLog was not created!" >> $testLog
   else
      # write test info for -encrypt to summary log
      echo "Information about testing with -encrypt:" >> $resultsLog
      echo -n "Seed value was: " >> $resultsLog
      cat "seed.txt" >> $resultsLog
      echo >> $resultsLog
      echo "Hexdump of memory region:" >> $resultsLog
      echo >> $resultsLog
      hexdump -C $encryptDmp >> $resultsLog   
      echo >> $resultsLog
   fi
   if [[ ! -e $encryptLog ]]; then
      echo "Error:  $encryptLog was not created!" >> $testLog
   else
      echo "Your output log:" >> $resultsLog
      echo >> $resultsLog
      cat $encryptLog >> $resultsLog
      echo >> $resultsLog
      echo $Separator >> $resultsLog
   fi
   
############################################################ Run Valgrind check

   # Full valgrind output is in $vgrindLog
   # Extracted counts are in $vgrindIssues

   # Because the test executes so quickly, we need to trigger a short
   # sleep to give the system clock time to update for the next test.
   sleep 1

   echo "Running valgrind test..." >> $vgrindLog
   vgrindSwitches=" --leak-check=full --show-leak-kinds=all --log-file=$vgrindLog --track-origins=yes -v"
   timeout 30 valgrind $vgrindSwitches $exeName -clear >> $vgrindLog 2>&1
   if [[ -s $tmpVgrind ]]; then
      cat $tmpVgrind >> $vgrindLog
   fi
   
   # accumulate valgrind error counts
   if [[ -e $vgrindLog ]]; then
      echo "Valgrind issues:" > $vgrindIssues
      grep "in use at exit" $vgrindLog >> $vgrindIssues
      grep "total heap usage" $vgrindLog >> $vgrindIssues
      grep "definitely lost" $vgrindLog >> $vgrindIssues
      echo "Invalid reads: `grep -c "Invalid read" $vgrindLog`" >> $vgrindIssues
      echo "Invalid writes: `grep -c "Invalid write" $vgrindLog`" >> $vgrindIssues
      echo "Uses of uninitialized values: `grep -c "uninitialised" $vgrindLog`" >> $vgrindIssues
   else
      echo "Error running Valgrind test." >> $testLog
   fi
   
   # Log test data/results for valgrind check
   echo >> $vgrindLog
   if [[ ! -e $clearDmp ]]; then
      # This should NEVER happen...
      echo "Error:  $clearDmp was not created!" >> $vgrindLog
   else
      # write test info for Valgrind check to summary log
      echo "Information about testing with Valgrind:" >> $vgrindLog
      echo -n "Seed value was: " >> $vgrindLog
      cat "seed.txt" >> $vgrindLog
      echo "Hexdump of memory region:" >> $vgrindLog
      echo >> $vgrindLog
      hexdump -C $clearDmp >> $vgrindLog   
      echo >> $vgrindLog
   fi
   if [[ ! -e $clearLog ]]; then
      echo "Error:  $clearLog was not created!" >> $vgrindLog
   else
      echo "Your output log:" >> $vgrindLog
      echo >> $vgrindLog
      cat $clearLog >> $vgrindLog
      echo >> $vgrindLog
      echo $Separator >> $vgrindLog
   fi
   
############################################################ File report
# complete summary file

   summaryLog="$sPID.txt"
   
   # write header to summary log
   cat "$headerLog" > $summaryLog
   echo $Separator >> $summaryLog
   
   # write score summary to log
   echo ">>Scores from testing<<" >> $summaryLog
   echo -n "  1 >> " >> $summaryLog
   grep "Score" $clearLog >> $summaryLog
   echo -n "  2 >> " >> $summaryLog
   grep "Score" $encryptLog >> $summaryLog
   echo >> $summaryLog
   echo "The first score is from the test with clear text." >> $summaryLog
   echo "The second score is from the test with encrypted text." >> $summaryLog
   echo "Your overall score is a weighted average of these two scores," >> $summaryLog
   echo "using the weights from the project specification." >> $summaryLog
   echo $Separator >> $summaryLog
   
   # Compute and log late penalty, if the needed log file exists
   if [[ -e $latePenaltyDataFile ]]; then
      computeLatePenalty $sPID
      if [[ -e $latePenaltyReport ]]; then
         cat $latePenaltyReport >> $summaryLog
         echo >> $summaryLog
      fi
      echo $Separator >> $summaryLog
   fi
   
   if [[ -s $vgrindIssues ]]; then
	   # write Valgrind summary into log
	   echo "Summary of valgrind results:" >> $summaryLog
	   echo >> $summaryLog
	   cat $vgrindIssues >> $summaryLog
	   echo $Separator >> $summaryLog
	else
	   echo "Valgrind summary log was not created." >> $summaryLog
   fi
   
   if [[ -e $resultsLog ]]; then
      cat $resultsLog >> $summaryLog
   fi
   
   if [[ -s $vgrindLog ]]; then
	   # write Valgrind details into log
	   echo "Details from valgrind check:" >> $summaryLog
	   echo >> $summaryLog
	   cat $vgrindLog >> $summaryLog
	   echo $Separator >> $summaryLog
	else
	   echo "Valgrind details log was not created." >> $summaryLog
   fi
   
   # write build log into summary
   echo "Results from $buildLog" >> $summaryLog
   cat $buildLog >> $summaryLog
   echo >> $summaryLog

exit 0
