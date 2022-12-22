#!/bin/bash

set -e

echo

echo "-- RUNNER STARTING"

echo
echo "Setting default options..."
# Which repos to run (true or false)
SEAL=true
PALISADE=true
HELIB=true

# Must be a tag, branch, or commit SHA
SEALVERSION="main"
SEALHEXLVERSION="main"

PALISADEVERSION="master"
PALISADEHEXLVERSION="main"

HELIBVERSION="master"
HELIBHEXLVERSION="development"
HELIBGBENCHVERSION="main"

# Must be ON or OFF
HEXL="ON"

# TEST TO RUN
PERFORMANCETEST=true
PERFSTATTEST=true
EMONTEST=true

# The file provided must exist AND must be named 'crypto-level-runner.config'
# Otherwise, the script will run using the defaults
CRYPTOLEVELCONFIG="Running With Defaults"

if [ $# -lt 2 ];
then
    echo
    echo "This script must be run with a several options to function correctly."
    echo "    1. A RUNTAG to identify this particular run"
    echo "    2. The path to the configuration file repository as pulled down by the user"
    echo "    3. OPTIONAL: The path to the bash configuration for controlling this run's dependency versions"
    echo "        - If not set, the script will use the its defaults"
    echo "    4. OPTIONAL: ON or OFF to Enable or Disable HEXL when running these libraries"
    echo "        - If not set, the script will use the its defaults"
    echo "Please run the script as follows:"
    echo "./crypto-level-runner.sh 'RUNTAG' 'PATH_TO_CONFIGURATION-FILE_REPO' [PATH_TO_BASH_CONFIG] [ON|OFF]"
    echo
    exit 1
elif [ $# -gt 1 ];
then
    RUNTAG=$1
    PATHTOCONFIGREPO=$(realpath $2)

    pushd $PATHTOCONFIGREPO
    if [ "$(git config --get remote.origin.url)" != "$REPO_LINK" ] && [ "$(git config --get remote.origin.url)" != "$REPO_LINK" ];
    then
        echo
        echo "The provided 2nd option is NOT a valid path to the Benchmarking Configuration File Repository"
        echo "Please clone it and provide the correct path to the repository as below:"
        echo "./crypto-level-runner.sh 'RUNTAG' 'PATH_TO_CONFIGURATION-FILE_REPO' [PATH_TO_BASH_CONFIG] [ON|OFF]"
        echo
        exit 1
    fi
    popd
fi
if [ $# -gt 2 ];
then
    if [ "$(basename $3)" = 'crypto-level-runner.config' ] && [ -f "$3" ];
    then
        echo "Modifying default options using the provided configuration file"
        CRYPTOLEVELCONFIG=$(realpath $3)
        echo
        pushd $(dirname $CRYPTOLEVELCONFIG)
        . ./$(basename $CRYPTOLEVELCONFIG)
        popd
    else
        echo
        echo "The provided configuration file either could not be found OR did not have the expected filename."
        echo "Please confirm that the below file exists before re-running this script:"
        echo
        echo "$(dirname $3)/crypto-level-runner.config"
        echo
        exit 1
    fi
fi
if [ $# -gt 3 ];
then
    if [ "$4" = "ON" ];
    then
        HEXL="ON"
    elif [ "$4" = "OFF" ];
    then
        HEXL="OFF"
    else
        echo
        echo "The optional second command-line parameter must be either set to 'ON' or 'OFF' for the HEXL usage status"
        echo "e.g. run the script as following:"
        echo "./crypto-level-runner.sh 'RUNTAG' 'PATH_TO_CONFIGURATION-FILE_REPO' [PATH_TO_BASH_CONFIG] [ON|OFF]"
        echo
        exit 1
    fi
fi

echo
echo "Checking Tool Dependencies..."
echo "At a minumum, the script requires the system it's running on to have several dependencies setup prior:"
echo "    1. Emon/Sep"
echo "    2. Perf Stat"
echo "Checking for the above tools..."
echo
if ! emon;
then
    echo
    echo "Emon wasn't installed properly."
    echo "Please Install Emon/Sep and run this script again"
    echo "Error Status Code: $?"
    echo
    exit 1
fi
if ! id -nG "$USER" | grep -qw vtune;
then
    echo
    echo "The user account running Emon must be included in the 'vtune' group."
    echo "The current user ($USER) is not part of the vtune group."
    echo "Please remedy this issue and re-run the script."
    echo
    exit 1
fi
echo
if ! perf stat ls;
then
    echo
    echo "Perf wasn't installed properly."
    echo "Please Install Perf and run this script again"
    echo "Error Status Code: $?"
    echo
    exit 1
fi


echo "Emon & Perf Stat Installations Found."
echo
echo "Running With the Following Options: "
echo "- RUNTAG:       $RUNTAG"
echo "- CONFIG REPO:  $PATHTOCONFIGREPO"
echo "- CONFIG:       $CRYPTOLEVELCONFIG"
echo "- HEXL:         $HEXL"

rm -rf ./auto-gen-test.config

echo "Run With the Following Libraries: "
if [ "$SEAL" = true ];
then
    echo "- SEAL:       $SEALVERSION"
    if [ "$HEXL" == "ON" ];
    then
        echo "    - SEAL-HEXL: $SEALHEXLVERSION"
    fi
    echo "1" >> auto-gen-test.config
fi
if [ "$PALISADE" = true ];
then
    echo "- PALISADE:   $PALISADEVERSION"
    if [ "$HEXL" == "ON" ];
    then
        echo "    - PALISADE-HEXL: $PALISADEHEXLVERSION"
    fi
    echo "2" >> auto-gen-test.config
fi
if [ "$HELIB" = true ];
then
    echo "- HElib:      $HELIBVERSION"
    if [ "$HEXL" == "ON" ];
    then
        echo "    - HElib-HEXL: $HELIBHEXLVERSION"
    fi
    echo "    - HElib-GBench: $HELIBGBENCHVERSION"
    echo "3" >> auto-gen-test.config
fi

echo "Running With the Following Tests: "
echo "- Basic Performance: $PERFORMANCETEST"
echo "- Perf Stat:         $PERFSTATTEST"
echo "- Emon HW Counters:  $EMONTEST"

if [ "$SEAL" = false ] && [ "$PALISADE" = false ] && [ "$HELIB" = false ];
then
    echo
    echo "At least one library must be run."
    echo "Please set at least one library to 'true' in the crypto-level-runner.config file"
    echo
    exit 1
fi

if [ "$PERFORMANCETEST" = false ] && [ "$PERFSTATTEST" = false ] && [ "$EMONTEST" = false ];
then
    echo
    echo "At least one test must be run."
    echo "Please set at least one test to 'true' in the primitive-level-runner.config file"
    echo
    exit 1
fi

echo
echo "-- RUNNER STARTING BUILD SCRIPT"
. ./crypto-level-build.sh
echo
echo "-- RUNNER COMPLETED BUILD SCRIPT"

echo
echo "-- RUNNER STARTING TEST SCRIPT"

echo "4" >> auto-gen-test.config

if [ "$SEAL" = true ];
then
    echo "$AUTO_SEAL_PATH" >> auto-gen-test.config
fi
if [ "$PALISADE" = true ];
then
    echo "$AUTO_PALISADE_PATH" >> auto-gen-test.config
fi
if [ "$HELIB" = true ];
then
    echo "$AUTO_HELIB_PATH" >> auto-gen-test.config
fi

echo >> auto-gen-test.config

echo "Auto Generated Test Script Options:"
cat auto-gen-test.config
echo

. ./crypto-level-test.sh < auto-gen-test.config

echo
echo "-- RUNNER COMPLETED TEST SCRIPT"

echo
echo "-- RUNNER SUCCESSFULLY COMPLETED"
exit 0
