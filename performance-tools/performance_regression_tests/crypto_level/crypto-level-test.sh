#!/bin/bash

set -e

STARTTIME=$(date +"%m_%d_%Y-%I_%M_%p")

# String for EMON to recognize which samples/counters it needs to pull
# This is set for ICX
EMONSTRING="($(<$PATHTOCONFIGREPO/other/performance_regression_tests/emon-dependencies/config/emon-string.txt) )"

# SLEEP NOTE:
#   For crypto_emon & crypto_perfstat, need a sleep or wait of some sort to avoid startup before g-bench operate starts
#   Simple Fix: Add pre-determined sleep before running emon/perfstat
#   Problem: Sleep will vary depending on HW (and SW?) configuration

# PARAMETERS
# $i = Path to benchmark executable (s.g. sealbench, lib-hexl-benchmark, etc.)
# $2 = Google Benchmark Filter to use
#    = Benchmarks are run one at a time to avoiad containmanation
# $3 = Name of the Library being run
#    = Primarily used for log/directory naming
# $4 = The time (in seconds) that emon should wait before collection
#    = See "SLEEP NOTE" above for more details
crypto_emon()
{
    local BENCHMARK=$1
    local FILTER=$2
    local LIBRARY=$3
    local SETUPTIME=$4
    local MINTIME=100; # Minimum GBench Time: Needs to run long enough to collect all emon samples (1-36) w/ high mux reliability
    local OUTFILE="results-crypto-level-$RUNTAG/emon-logs/$LIBRARY/$HEXL_STATUS/crypto-emon-${LIBRARY}-${HEXL_STATUS}-$STARTTIME.log"
    local BENCHEXE=$(basename $BENCHMARK)

    echo -e "\n\n$COUNTER. Running: OMP_NUM_THREADS=1 emon -q -c -experimental -s$SETUPTIME -C '$EMONSTRING' -f results-crypto-level-$RUNTAG/emon-logs/$LIBRARY/$HEXL_STATUS/crypto-emon-$LIBRARY-$HEXL_STATUS-$BENCHEXE#${COUNTER}-$STARTTIME.dat /usr/bin/numactl --cpunodebind=0 --membind=0 -C 0 $BENCHMARK --benchmark_filter='^$FILTER$' --benchmark_min_time=$MINTIME" | tee -a $OUTFILE
    OMP_NUM_THREADS=1 emon -q -c -experimental -s$SETUPTIME -C "$EMONSTRING" -f results-crypto-level-$RUNTAG/emon-logs/$LIBRARY/$HEXL_STATUS/crypto-emon-$LIBRARY-$HEXL_STATUS-$BENCHEXE\#${COUNTER}-$STARTTIME.dat /usr/bin/numactl --cpunodebind=0 --membind=0 -C 0 $BENCHMARK --benchmark_filter="^$FILTER$" --benchmark_min_time=$MINTIME |& tee -a $OUTFILE

    #PROCESS .DAT FILE 
    rm results-crypto-level-$RUNTAG/emon-logs/$LIBRARY/$HEXL_STATUS/crypto-emon-$LIBRARY-$HEXL_STATUS-$BENCHEXE\#${COUNTER}-$STARTTIME.dat
    #CLEAN-UP
}

# PARAMETERS
# $i = Path to benchmark executable (s.g. sealbench, lib-hexl-benchmark, etc.)
# $2 = Google Benchmark Filter to use
#    = Benchmarks are run one at a time to avoiad containmanation
# $3 = Name of the Library being run
#    = Primarily used for log/directory naming
# $4 = The time (in seconds) that emon should wait before collection
#    = See "SLEEP NOTE" above for more details
crypto_perfstat()
{
    local BENCHMARK=$1
    local FILTER=$2
    local LIBRARY=$3
    local SETUPTIME=$4
    local MINTIME=8; # Minimum GBench Time
    local OUTFILE="results-crypto-level-$RUNTAG/perfstat-logs/$LIBRARY/$HEXL_STATUS/crypto-perfstat-${LIBRARY}-${HEXL_STATUS}-$STARTTIME.log"
    local BENCHEXE=$(basename $BENCHMARK)
    
    echo -e "\n\n$COUNTER. Running: OMP_NUM_THREADS=1 /usr/bin/numactl --cpunodebind=0 --membind=0 -C 0 $BENCHMARK --benchmark_filter='^$FILTER$' --benchmark_min_time=$MINTIME & PID=$(pgrep $(echo '$BENCHEXE' | cut -c1-15)) && sleep $SETUPTIME && perf stat -p $PID -C 0" | tee -a $OUTFILE
  
    OMP_NUM_THREADS=1 /usr/bin/numactl --cpunodebind=0 --membind=0 -C 0 $BENCHMARK --benchmark_filter="^$FILTER$" --benchmark_min_time=$MINTIME & PID=$(pgrep $(echo "$BENCHEXE" | cut -c1-15)) && sleep $SETUPTIME && perf stat -p $PID -C 0 |& tee -a $OUTFILE
}

# PARAMETERS
# $i = Path to benchmark executable (s.g. sealbench, lib-hexl-benchmark, etc.)
# $2 = Name of the Library being run
#    = Primarily used for log/directory naming
crypto_performance()
{
    local BENCHMARK=$1
    local LIBRARY=$2
    local MINTIME=8;
    local OUTFILE="results-crypto-level-$RUNTAG/performance-logs/$LIBRARY/$HEXL_STATUS/crypto-performance-${LIBRARY}-${HEXL_STATUS}-$STARTTIME.log"
    echo $OUTFILE
    
    echo -e "\n\nRunning: OMP_NUM_THREADS=1 /usr/bin/numactl --cpunodebind=0 --membind=0 -C 0 $BENCHMARK --benchmark_format=csv --benchmark_min_time=$MINTIME" | tee -a $OUTFILE
    OMP_NUM_THREADS=1 /usr/bin/numactl --cpunodebind=0 --membind=0 -C 0 $BENCHMARK --benchmark_format=csv --benchmark_min_time=$MINTIME | tee -a $OUTFILE
    sed -i '/,,,,,\|name,iterations,\|Running:/!d' $OUTFILE
}

# PARAMETERS:
# $1 = PATH TO HElib BUILD/INSTALL DIRECTORY
#    = Directory must have the "bin" directory present
#    = Sometimes this isn't the same as the install directory depending on the repository
loop_helib()
{
    echo -e "\n\nRunning HElib Benchmarks"
    local INSTALL_PATH=$1
    local benchmarks_to_run=($INSTALL_PATH/bin/ckks_basic $INSTALL_PATH/bin/bgv_basic $INSTALL_PATH/bin/fft_bench)
  
    echo "Running: ${benchmarks_to_run[0]}"
    if $PERFORMANCETEST
    then
        crypto_performance "${benchmarks_to_run[0]}" "HELIB"
    fi
    mapfile -t helib_array < <( "${benchmarks_to_run[0]}" --benchmark_list_tests=true )

    local CLEAN_FILTER_ARRAY=()
    local val=0
    COUNTER=1
    for i in "${helib_array[@]}"
    do
        i=${i// /.}
        i=${i//\)/\\)}
        i=${i//\(/\\(}
        CLEAN_FILTER_ARRAY+=("$i")
    
        # Account for long pre-commute on HElib fft_bench F4
        if [[ "$i" == *"F4_params"* ]]
        then
            if $PERFSTATTEST
            then
                crypto_perfstat "${benchmarks_to_run[0]}" "$i" "HELIB" "26"
            fi
            if $EMONTEST
            then
                crypto_emon "${benchmarks_to_run[0]}" "$i" "HELIB" "26"
            fi
        else
            if $PERFSTATTEST
            then
                crypto_perfstat "${benchmarks_to_run[0]}" "$i" "HELIB" "2"
            fi
            if $EMONTEST
            then
                crypto_emon "${benchmarks_to_run[0]}" "$i" "HELIB" "2"
            fi
        fi
        COUNTER=$((COUNTER+1))
    done

    echo "Running: ${benchmarks_to_run[1]}"
    if $PERFORMANCETEST
    then
        crypto_performance "${benchmarks_to_run[1]}" "HELIB"
    fi
    mapfile -t helib_array < <( "${benchmarks_to_run[1]}" --benchmark_list_tests=true )

    val=0
    COUNTER=1
    for i in "${helib_array[@]}"
    do
        i=${i// /.}
        i=${i//\)/\\)}
        i=${i//\(/\\(}
        CLEAN_FILTER_ARRAY+=("$i")
        if $PERFSTATTEST
        then
            crypto_perfstat "${benchmarks_to_run[1]}" "$i" "HELIB" "1"
        fi
        if $EMONTEST
        then
            crypto_emon "${benchmarks_to_run[1]}" "$i" "HELIB" "1"
        fi
        COUNTER=$((COUNTER+1))
    done
  
    echo "Running: ${benchmarks_to_run[2]}"
    if $PERFORMANCETEST
    then
        crypto_performance "${benchmarks_to_run[2]}" "HELIB"
    fi
    mapfile -t helib_array < <( "${benchmarks_to_run[2]}" --benchmark_list_tests=true )

    val=0
    COUNTER=1
    for i in "${helib_array[@]}"
    do
        i=${i// /.}
        i=${i//\)/\\)}
        i=${i//\(/\\(}
        CLEAN_FILTER_ARRAY+=("$i")
        if $PERFSTATTEST
        then
            crypto_perfstat "${benchmarks_to_run[2]}" "$i" "HELIB" "2"
        fi
        if $EMONTEST
        then
            crypto_emon "${benchmarks_to_run[2]}" "$i" "HELIB" "2"
        fi
        COUNTER=$((COUNTER+1))
    done

    if $PERFSTATTEST
    then
        . ../common-scripts/parse-perfstat-results.sh "results-crypto-level-$RUNTAG/perfstat-logs/HELIB/$HEXL_STATUS/crypto-perfstat-HELIB-${HEXL_STATUS}-$STARTTIME.log"
    fi
}

# PARAMETERS:
# $1 = PATH TO PALISADE BUILD/INSTALL DIRECTORY
#    = Directory must have the "bin" directory present
#    = Sometimes this isn't the same as the install directory depending on the repository
loop_palisade()
{
    echo -e "\n\nRunning PALISADE Benchmarks"
    local INSTALL_PATH=$1
    local benchmarks_to_run=($INSTALL_PATH/bin/benchmark/lib-hexl-benchmark)

    echo "Running: ${benchmarks_to_run[0]}"
    if $PERFORMANCETEST
    then
        crypto_performance "${benchmarks_to_run[0]}" "PALISADE"
    fi
    mapfile -t palisade_array < <( ${benchmarks_to_run[0]} --benchmark_list_tests=true )

    local CLEAN_FILTER_ARRAY=()
    local val=0
    COUNTER=1
    for i in "${palisade_array[@]}"
    do
        i=${i// /.}
        i=${i//\)/\\)}
        i=${i//\(/\\(}
        CLEAN_FILTER_ARRAY+=("$i")
        if $PERFSTATTEST
        then
            crypto_perfstat "${benchmarks_to_run[0]}" "$i" "PALISADE" "1"
        fi
        if $EMONTEST
        then
            crypto_emon "${benchmarks_to_run[0]}" "$i" "PALISADE" "1"
        fi
        COUNTER=$((COUNTER+1))
    done

    if $PERFSTATTEST
    then
        . ../common-scripts/parse-perfstat-results.sh "results-crypto-level-$RUNTAG/perfstat-logs/PALISADE/$HEXL_STATUS/crypto-perfstat-PALISADE-${HEXL_STATUS}-$STARTTIME.log"
    fi
}

# PARAMETERS:
# $1 = PATH TO SEAL BUILD/INSTALL DIRECTORY
#    = Directory must have the "bin" directory present
#    = Sometimes this isn't the same as the install directory depending on the repository
loop_seal() 
{
    echo -e "\n\nRunning SEAL Benchmarks"
    local INSTALL_PATH=$1
    local benchmarks_to_run=($INSTALL_PATH/bin/sealbench)

    echo "Running: ${benchmarks_to_run[0]}"
    if $PERFORMANCETEST
    then
        crypto_performance "${benchmarks_to_run[0]}" "SEAL"
    fi
    mapfile -t seal_array < <( ${benchmarks_to_run[0]} --benchmark_list_tests=true )

    local CLEAN_FILTER_ARRAY=()
    local val=0
    COUNTER=1
    for i in "${seal_array[@]}"
    do
        if [[ $i != n=* ]]
        then
            continue
        fi

        i=${i// /.}
        i=${i//\)/\\)}
        i=${i//\(/\\(}
        CLEAN_FILTER_ARRAY+=("$i")
        if $PERFSTATTEST
        then
            crypto_perfstat "${benchmarks_to_run[0]}" "$i" "SEAL" "5"
        fi
        if $EMONTEST
        then
            crypto_emon "${benchmarks_to_run[0]}" "$i" "SEAL" "5"
        fi
        COUNTER=$((COUNTER+1))
    done

    if $PERFSTATTEST
    then
        . ../common-scripts/parse-perfstat-results.sh "results-crypto-level-$RUNTAG/perfstat-logs/SEAL/$HEXL_STATUS/crypto-perfstat-SEAL-${HEXL_STATUS}-$STARTTIME.log" 
    fi
}

TEST_SEAL=false
TEST_PALISADE=false
TEST_HELIB=false

# Selects which libraries to run
# If none are selected, the default is that all libraries will be run
PS3='ONE AT A TIME, please select the number each of the libraries youd like to test and then Continue to move on (or just "Continue" to select all): '
options=("SEAL" "PALISADE" "HElib" "Continue" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "SEAL")
            echo "Adding $opt to the set of benchmarks"
            TEST_SEAL=true
            ;;
        "PALISADE")
            echo "Adding $opt to the set of benchmarks"
            TEST_PALISADE=true
            ;;
        "HElib")
            echo "Adding $opt to the set of benchmarks"
            TEST_HELIB=true
            ;;
        "Continue")
            if ! $TEST_SEAL && ! $TEST_PALISADE && ! $TEST_HELIB 
            then
                echo "You didn't select any benchmarks to run, running all benchmarks by default."
                read -p "Press any key to continue (or CTRL+C to cancel)"
                TEST_SEAL=true
                TEST_PALISADE=true
                TEST_HELIB=true
            else
                echo "Running the following benchmarks:"
                echo "- SEAL ($TEST_SEAL)"
                echo "- PALISADE ($TEST_PALISADE)"
                echo "- HElib ($TEST_HELIB)"
            fi
            break
            ;;
        "Quit")
            echo "Exiting Script"
            exit 0
            ;;
        *) echo "invalid option $REPLY";;
    esac
done

SEAL_PATH=""
PALISADE_PATH=""
HELIB_PATH=""

if $TEST_SEAL
then
    read -e -p 'Please Enter the path to your SEAL build directory: ' SEAL_PATH
    SEAL_PATH=$(realpath $SEAL_PATH)
    if [ ! -d "$SEAL_PATH" ] || [ ! -f "$SEAL_PATH/bin/sealbench" ]
    then
        echo "Can not find SEAL installation at the following directory: $SEAL_PATH"
        echo "Check that the directory exists and that SEAL is installed correctly"
        exit 1  
    fi
fi

if $TEST_PALISADE
then
    read -e -p 'Please Enter the path to your PALISADE build directory: ' PALISADE_PATH
    PALISADE_PATH=$(realpath $PALISADE_PATH)
    if [ ! -d "$PALISADE_PATH" ] || [ ! -f "$PALISADE_PATH/bin/benchmark/lib-hexl-benchmark" ]
    then
        echo "Can not find PALISADE installation at the following directory: $PALISADE_PATH"
        echo "Check that the directory exists and that PALISADE is installed correctly"
        echo "e.g. there should be a bin and lib folder in the above directory"
        exit 1
    fi
fi

if $TEST_HELIB
then
    read -e -p 'Please Enter the path to your HElib benchmarks build directory: ' HELIB_PATH
    HELIB_PATH=$(realpath $HELIB_PATH)
    if [ ! -d "$HELIB_PATH" ] || [ ! -f "$HELIB_PATH/bin/fft_bench" ] || [ ! -f "$HELIB_PATH/bin/ckks_basic" ] || [ ! -f "$HELIB_PATH/bin/bgv_basic" ]
    then
        echo "Can not find HElib installation at the following directory: $HELIB_PATH"
        echo "Check that the directory exists and that HElib is installed correctly"
        exit 1
    fi
fi

read -p 'This will remove any previously run results, press any key to continue (or CTRL+C to exit)'
if [ -z "$RUNTAG" ];
then
    echo
    echo "A 'RUNTAG' must be set to identify this particular run."
    echo "Either run this script with the included 'crypto-level-runner.sh' script, or set the RUNTAG environment variable before running this script."
    echo 
    exit 1
fi

if $PERFORMANCETEST
then
    PERFOUTPUT="results-crypto-level-$RUNTAG/performance-logs"
    mkdir -p $PERFOUTPUT
fi
if $PERFSTATTEST
then
    STATOUTPUT="results-crypto-level-$RUNTAG/perfstat-logs"
    mkdir -p $STATOUTPUT
fi
if $EMONTEST
then
    EMONOUTPUT="results-crypto-level-$RUNTAG/emon-logs"
    mkdir -p $EMONOUTPUT
    emon -v &> results-crypto-level-$RUNTAG/emon-logs/emon-v-$STARTTIME.txt
    emon -M &> results-crypto-level-$RUNTAG/emon-logs/emon-M-$STARTTIME.txt
fi

if [ "$HEXL" == "ON" ];
then
    HEXL_STATUS="hexl"
elif [ "$HEXL" == "OFF" ];
then
    HEXL_STATUS="nohexl"
else
    echo
    echo "HEXL environment variable wasn't set to either 'ON' or 'OFF'."
    echo "Either run this script with the included 'crypto-level-runner.sh' script, or set the HEXL environment variable based on your usage"
    echo
    exit 1
fi

echo "$RUNTAG: $STARTTIME" >> results-crypto-level-$RUNTAG/STARTED.log
echo "  Process PID: $$" >> results-crypto-level-$RUNTAG/STARTED.log

if $TEST_SEAL
then
    if $PERFORMANCETEST
    then
        mkdir -p $PERFOUTPUT/SEAL/$HEXL_STATUS
        rm -rf $PERFOUTPUT/SEAL/$HEXL_STATUS/*
    fi
    if $PERFSTATTEST
    then
        mkdir -p $STATOUTPUT/SEAL/$HEXL_STATUS
        rm -rf $STATOUTPUT/SEAL/$HEXL_STATUS/*
    fi
    if $EMONTEST
    then
        mkdir -p $EMONOUTPUT/SEAL/$HEXL_STATUS
        rm -rf $EMONOUTPUT/SEAL/$HEXL_STATUS/*
    fi

    loop_seal "$SEAL_PATH"  
fi
if $TEST_PALISADE
then
    if $PERFORMANCETEST
    then
        mkdir -p $PERFOUTPUT/PALISADE/$HEXL_STATUS
        rm -rf $PERFOUTPUT/PALISADE/$HEXL_STATUS/*
    fi
    if $PERFSTATTEST
    then
        mkdir -p $STATOUTPUT/PALISADE/$HEXL_STATUS
        rm -rf $STATOUTPUT/PALISADE/$HEXL_STATUS/*
    fi
    if $EMONTEST
    then
        mkdir -p $EMONOUTPUT/PALISADE/$HEXL_STATUS
        rm -rf $EMONOUTPUT/PALISADE/$HEXL_STATUS/*
    fi

    loop_palisade "$PALISADE_PATH"
fi
if $TEST_HELIB
then
    if $PERFORMANCETEST
    then
        mkdir -p $PERFOUTPUT/HELIB/$HEXL_STATUS
        rm -rf $PERFOUTPUT/HELIB/$HEXL_STATUS/*
    fi
    if $PERFSTATTEST
    then
        mkdir -p $STATOUTPUT/HELIB/$HEXL_STATUS
        rm -rf $STATOUTPUT/HELIB/$HEXL_STATUS/*
    fi
    if $EMONTEST
    then
        mkdir -p $EMONOUTPUT/HELIB/$HEXL_STATUS
        rm -rf $EMONOUTPUT/HELIB/$HEXL_STATUS/*
    fi

    loop_helib "$HELIB_PATH"
    rm helib.log
fi

ENDTIME=$(date +"%m_%d_%Y-%I_%M_%p")
echo "$RUNTAG: $ENDTIME" >> results-crypto-level-$RUNTAG/FINISHED.log
