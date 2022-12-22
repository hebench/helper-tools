#!/bin/bash

set -e

STARTTIME=$(date +"%m_%d_%Y-%I_%M_%p")

# String for EMON to recognize which samples/counters it needs to pull
# This is set SPECIFICALLY for ICX
EMONSTRING="($(<$PATHTOCONFIGREPO/other/performance_regression_tests/emon-dependencies/config/emon-string.txt) )"

# SLEEP NOTE:
#   For primitive_emon & primitive_perfstat, need a sleep or wait of some sort to avoid startup before g-bench operate starts
#   Simple Fix: Add pre-determined sleep before running emon/perfstat
#   Problem: Sleep will vary depending on HW (and SW?) configuration

# PARAMETERS
# $i = Path to benchmark executable (s.g. bench_hexl)
# $2 = Google Benchmark Filter to use
#    = Benchmarks are run one at a time to avoiad containmanation
# $3 = Name of the Library being run
#    = Primarily used for log/directory naming
# $4 = The time (in seconds) that emon should wait before collection
#    = See "SLEEP NOTE" above for more details
primitive_emon()
{
    local BENCHMARK=$1
    local FILTER=$2
    local LIBRARY=$3
    local SETUPTIME=$4
    local MINTIME=100; # Minimum GBench Time: Needs to run long enough to collect all emon samples (1-36) w/ high mux reliability
    local OUTFILE="results-primitive-level-$RUNTAG/emon-logs/$LIBRARY/primitive-emon-${LIBRARY}-$STARTTIME.log"
    local BENCHEXE=$(basename $BENCHMARK)

    echo -e "\n\n$COUNTER. Running: OMP_NUM_THREADS=1 emon -q -c -experimental -s$SETUPTIME -C '$EMONSTRING' -f results-primitive-level-$RUNTAG/emon-logs/$LIBRARY/primitive-emon-$LIBRARY-$BENCHEXE#${COUNTER}-$STARTTIME.dat /usr/bin/numactl --cpunodebind=0 --membind=0 -C 0 $BENCHMARK --benchmark_filter='^$FILTER$' --benchmark_min_time=$MINTIME" | tee -a $OUTFILE
    OMP_NUM_THREADS=1 emon -q -c -experimental -s$SETUPTIME -C "$EMONSTRING" -f results-primitive-level-$RUNTAG/emon-logs/$LIBRARY/primitive-emon-$LIBRARY-$BENCHEXE\#${COUNTER}-$STARTTIME.dat /usr/bin/numactl --cpunodebind=0 --membind=0 -C 0 $BENCHMARK --benchmark_filter="^$FILTER$" --benchmark_min_time=$MINTIME |& tee -a $OUTFILE

    # PROCESS .DAT FILE 
 
    rm results-primitive-level-$RUNTAG/emon-logs/$LIBRARY/primitive-emon-$LIBRARY-$BENCHEXE\#${COUNTER}-$STARTTIME.dat
    # CLEANUP 
}

# PARAMETERS
# $i = Path to benchmark executable (s.g. bench_hexl)
# $2 = Google Benchmark Filter to use
#    = Benchmarks are run one at a time to avoiad containmanation
# $3 = Name of the Library being run
#    = Primarily used for log/directory naming
# $4 = The time (in seconds) that emon should wait before collection
#    = See "SLEEP NOTE" above for more details
primitive_perfstat()
{
    local BENCHMARK=$1
    local FILTER=$2
    local LIBRARY=$3
    local SETUPTIME=$4
    local MINTIME=8; # Minimum GBench Time
    local OUTFILE="results-primitive-level-$RUNTAG/perfstat-logs/$LIBRARY/primitive-perfstat-${LIBRARY}-$STARTTIME.log"
    local BENCHEXE=$(basename $BENCHMARK)
    
    echo -e "\n\n$COUNTER. Running: OMP_NUM_THREADS=1 /usr/bin/numactl --cpunodebind=0 --membind=0 -C 0 $BENCHMARK --benchmark_filter='^$FILTER$' --benchmark_min_time=$MINTIME & PID=$(pgrep $(echo '$BENCHEXE' | cut -c1-15)) && sleep $SETUPTIME && perf stat -p $PID -C 0" | tee -a $OUTFILE
  
    OMP_NUM_THREADS=1 /usr/bin/numactl --cpunodebind=0 --membind=0 -C 0 $BENCHMARK --benchmark_filter="^$FILTER$" --benchmark_min_time=$MINTIME & PID=$(pgrep $(echo "$BENCHEXE" | cut -c1-15)) && sleep $SETUPTIME && perf stat -p $PID -C 0 |& tee -a $OUTFILE
}

# PARAMETERS
# $i = Path to benchmark executable (s.g. bench_hexl)
# $2 = Name of the Library being run
#    = Primarily used for log/directory naming
primitive_performance()
{
    local BENCHMARK=$1
    local LIBRARY=$2
    local MINTIME=0.5;
    local OUTFILE="results-primitive-level-$RUNTAG/performance-logs/$LIBRARY/primitive-performance-${LIBRARY}-$STARTTIME.log"
    echo $OUTFILE
    
    echo -e "\n\nRunning: OMP_NUM_THREADS=1 /usr/bin/numactl --cpunodebind=0 --membind=0 -C 0 $BENCHMARK --benchmark_format=csv --benchmark_min_time=$MINTIME" | tee -a $OUTFILE
    OMP_NUM_THREADS=1 /usr/bin/numactl --cpunodebind=0 --membind=0 -C 0 $BENCHMARK --benchmark_format=csv --benchmark_min_time=$MINTIME | tee -a $OUTFILE
    sed -i '/,,,,,\|name,iterations,\|Running:/!d' $OUTFILE
}

# PARAMETERS:
# $1 = PATH TO HEXL BUILD/INSTALL DIRECTORY
#    = Directory must have the "bin" directory present
#    = Sometimes this isn't the same as the install directory depending on the repository
loop_hexl() 
{
    echo -e "\n\nRunning HEXL Benchmarks"
    local INSTALL_PATH=$1
    local benchmarks_to_run=($INSTALL_PATH/benchmark/bench_hexl)

    echo "Running: ${benchmarks_to_run[0]}"

    if $PERFORMANCETEST
    then
        primitive_performance "${benchmarks_to_run[0]}" "HEXL"
    fi

    mapfile -t hexl_array < <( ${benchmarks_to_run[0]} --benchmark_list_tests=true )

    local CLEAN_FILTER_ARRAY=()
    local val=0
    COUNTER=1
    for i in "${hexl_array[@]}"
    do
        i=${i// /.}
        i=${i//\)/\\)}
        i=${i//\(/\\(}
        CLEAN_FILTER_ARRAY+=("$i")
        if $PERFSTATTEST
        then
            primitive_perfstat "${benchmarks_to_run[0]}" "$i" "HEXL" "5"
        fi
        if $EMONTEST
        then
            primitive_emon "${benchmarks_to_run[0]}" "$i" "HEXL" "5"
        fi
        COUNTER=$((COUNTER+1))
    done

    if $PERFSTATTEST
    then
        . ../common-scripts/parse-perfstat-results.sh "results-primitive-level-$RUNTAG/perfstat-logs/HEXL/primitive-perfstat-HEXL-$STARTTIME.log" 
    fi
}

TEST_HEXL=false

# Selects which libraries to run
# If none are selected, the default is that all libraries will be run
PS3='ONE AT A TIME, please select the number each of the libraries youd like to test and then Continue to move on (or just "Continue" to select all): '
options=("HEXL" "Continue" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "HEXL")
            echo "Adding $opt to the set of benchmarks"
            TEST_HEXL=true
            ;;
        "Continue")
            if ! $TEST_HEXL
            then
                echo "You didn't select any benchmarks to run, running all benchmarks by default."
                read -p "Press any key to continue (or CTRL+C to cancel)"
                TEST_HEXL=true
            else
                echo "Running the following benchmarks:"
                echo "- HEXL ($TEST_HEXL)"
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

HEXL_PATH=""

if $TEST_HEXL
then
    read -e -p 'Please Enter the path to your HEXL build directory: ' HEXL_PATH
    HEXL_PATH=$(realpath $HEXL_PATH)
    if [ ! -d "$HEXL_PATH" ] || [ ! -f "$HEXL_PATH/benchmark/bench_hexl" ]
    then
        echo "Can not find HEXL installation at the following directory: $HEXL_PATH"
        echo "Check that the directory exists and that HEXL is installed correctly"
        exit 1  
    fi
fi

read -p 'This will remove any previously run results, press any key to continue (or CTRL+C to exit)'
if [ -z "$RUNTAG" ];
then
    echo
    echo "A 'RUNTAG' must be set to identify this particular run."
    echo "Either run this script with the included 'primitive-level-runner.sh' script, or set the RUNTAG environment variable before running this script."
    echo 
    exit 1
fi

if $PERFORMANCETEST
then
    PERFOUTPUT="results-primitive-level-$RUNTAG/performance-logs"
    mkdir -p $PERFOUTPUT
fi
if $PERFSTATTEST
then
    STATOUTPUT="results-primitive-level-$RUNTAG/perfstat-logs"
    mkdir -p $STATOUTPUT
fi
if $EMONTEST
then
    EMONOUTPUT="results-primitive-level-$RUNTAG/emon-logs"
    mkdir -p $EMONOUTPUT
    emon -v &> results-primitive-level-$RUNTAG/emon-logs/emon-v-$STARTTIME.txt
    emon -M &> results-primitive-level-$RUNTAG/emon-logs/emon-M-$STARTTIME.txt
fi

echo "$RUNTAG: $STARTTIME" >> results-primitive-level-$RUNTAG/STARTED.log
echo "  Process PID: $$" >> results-primitive-level-$RUNTAG/STARTED.log

if $TEST_HEXL
then
    if $PERFORMANCETEST
    then
        mkdir -p $PERFOUTPUT/HEXL
        rm -rf $PERFOUTPUT/HEXL/*
    fi
    if $PERFSTATTEST
    then
        mkdir -p $STATOUTPUT/HEXL
        rm -rf $STATOUTPUT/HEXL/*
    fi
    if $EMONTEST
    then
        mkdir -p $EMONOUTPUT/HEXL
        rm -rf $EMONOUTPUT/HEXL/*
    fi

    loop_hexl "$HEXL_PATH"  
fi

ENDTIME=$(date +"%m_%d_%Y-%I_%M_%p")
echo "$RUNTAG: $ENDTIME" >> results-primitive-level-$RUNTAG/FINISHED.log
