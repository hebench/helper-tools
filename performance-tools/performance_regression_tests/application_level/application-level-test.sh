#!/bin/bash

set -e

STARTTIME=$(date +"%m_%d_%Y-%I_%M_%p")

EMONSTRING="($(<$PATHTOCONFIGREPO/other/performance_regression_tests/emon-dependencies/config/emon-string.txt) )"

application_emon()
{
    local NUM=$1
    local LIBRARY=$2
    local SINGLECONFIGPATH=$3
    shift && shift && shift
    local BENCHMARK=("$@")
    local OUTFILE="results-application-level-$RUNTAG/emon-logs/$LIBRARY/$HEXL_STATUS/application-emon-${LIBRARY}-${HEXL_STATUS}-$STARTTIME.log"

    local TMPDIR="/tmp/temp-dump-dir"

    mkdir -p $TMPDIR
    rm -rf $TMPDIR/*

    echo
    touch $TMPDIR/temp.txt
    sleep 2
    echo  "(time emon -q -l2 -t4 -c -experimental -C "$EMONSTRING" -f results-application-level-$RUNTAG/emon-logs/$LIBRARY/$HEXL_STATUS/application-emon-$LIBRARY-$HEXL_STATUS-$BENCHEXE\#${NUM}-$STARTTIME.dat ${BENCHMARK[0]} -b ${BENCHMARK[1]} --output_dir $TMPDIR --single_path --config_file $SINGLECONFIGPATH) &> >(tee $TMPDIR/temp.txt) & sleep 0.5 && emon -pause &" |& tee -a $OUTFILE
    (time emon -q -l2 -t4 -c -experimental -C "$EMONSTRING" -f results-application-level-$RUNTAG/emon-logs/$LIBRARY/$HEXL_STATUS/application-emon-$LIBRARY-$HEXL_STATUS-$BENCHEXE\#${NUM}-$STARTTIME.dat ${BENCHMARK[0]} -b ${BENCHMARK[1]} --output_dir $TMPDIR --single_path --config_file $SINGLECONFIGPATH) &> >(tee $TMPDIR/temp.txt) & sleep 0.5 && emon -pause &
    ( tail -f -n0 $TMPDIR/temp.txt & ) | grep -q "Testing...";

    sleep 2
    emon -resume
    sleep 2

    ( tail -f -n0 $TMPDIR/temp.txt & ) | grep -q "real.*s";

    sleep 2

    # PROCESS .DAT FILE

    rm -rf $TMPDIR
    rm results-application-level-$RUNTAG/emon-logs/$LIBRARY/$HEXL_STATUS/application-emon-$LIBRARY-$HEXL_STATUS-$BENCHEXE\#${NUM}-$STARTTIME.dat
    # REMOVE EXCESS FILES
}

application_perfstat()
{
    local NUM=$1
    local LIBRARY=$2
    local SINGLECONFIGPATH=$3
    shift && shift && shift
    local BENCHMARK=("$@")
    local OUTFILE="results-application-level-$RUNTAG/perfstat-logs/$LIBRARY/$HEXL_STATUS/application-perfstat-${LIBRARY}-${HEXL_STATUS}-$STARTTIME.log"

    local TMPDIR="/tmp/temp-dump-dir" 

    mkdir -p $TMPDIR
    rm -rf $TMPDIR/*

    echo
    touch $TMPDIR/temp.txt
    sleep 2
    echo  "Running Config ID #$NUM: ${BENCHMARK[0]} --backend ${BENCHMARK[1]} --output_dir $TMPDIR --single_path --config_file $SINGLECONFIGPATH |& tee $TMPDIR/temp.txt & PID=PID" |& tee -a $OUTFILE
    ${BENCHMARK[0]} --backend ${BENCHMARK[1]} --output_dir $TMPDIR --single_path --config_file $SINGLECONFIGPATH &> >(tee $TMPDIR/temp.txt) &
    PID=$!
    ( tail -f -n0 $TMPDIR/temp.txt & ) | grep -q "Testing...";
 
    sleep 2
    perf stat -p $PID --timeout 8000 |& tee -a $OUTFILE
    sleep 2
    
    sudo kill -9 $PID
    sleep 2
    rm -rf $TMPDIR
}

application_performance()
{
    local LIBRARY=$1
    local CONFIGFILE=$2
    shift && shift
    local BENCHMARK=("$@")
    local OUTDIR="results-application-level-$RUNTAG/performance-logs/$LIBRARY/$HEXL_STATUS/"

    mkdir -p $OUTDIR
    echo "Output Directory for Results: $OUTDIR"
    
    echo
    echo "Running Performance Test: ${BENCHMARK[0]} --backend ${BENCHMARK[1]} --output_dir $OUTDIR --single_path --config_file $CONFIGFILE"
    ${BENCHMARK[0]} --backend ${BENCHMARK[1]} --output_dir $OUTDIR --single_path --config_file $CONFIGFILE

    pushd $OUTDIR
    tar --exclude "benchmark_list*" --remove-files -czvf ${LIBRARY}-${HEXL_STATUS}-hebench-reports-$STARTTIME.tar.gz *
    popd
}

loop_refseal() 
{
    echo -e "\n\nRunning REFERENCE SEAL BACKEND Benchmarks"
    local INSTALL_PATH=$1
    local benchmarks_to_run=($INSTALL_PATH/bin/test_harness $INSTALL_PATH/lib/libhebench_seal_backend.so)
    local CONFIGFILE="$PATHTOCONFIGREPO/$REFSEALHEBCONFIG"

    mkdir -p temp-folder && rm -rf temp-folder/*
    pushd temp-folder
    if [ ! -f $CONFIGFILE ];
    then
        echo
        echo "----ALERT----: PROVIDED CONFIGURATION FILE NOT FOUND. RUNNING WITH BASE. ----ALERT----"
        echo
        ${benchmarks_to_run[0]} -b ${benchmarks_to_run[1]} --config_file refseal_base_config_file.yml --dump
        CONFIGFILE=$(realpath ./refseal_base_config_file.yml)
    fi
    popd

    if $PERFORMANCETEST
    then
        echo "Setting Minimum Test Time to sufficient amount to avoid spin/warm-up time"
        sed '0,/default_min_test_time/{s/default_min_test_time.*/default_min_test_time: 5000/}' -i $CONFIGFILE
        application_performance "REFSEAL" "$CONFIGFILE" "${benchmarks_to_run[@]}"
    fi

    if $PERFSTATTEST || $EMONTEST
    then
        echo "Setting Minimum Test Time to sufficient amount for Hardware Counter capture (it will be killed before completion)"
        sed '0,/default_min_test_time/{s/default_min_test_time.*/default_min_test_time: 500000/}' -i $CONFIGFILE

        pushd temp-folder
        if ! command -v yq &> /dev/null
        then
            echo "YQ Tool is not installed, installing it..."
            ../../../hebench_config_tools/yq_install.sh
            rm install-man-page.sh
            rm yq.1
            echo "YQ Tool Installed Successfully"
        fi

        local CLEAN_FILTER_ARRAY=()
        GETTESTIDS=$(../../../hebench_config_tools/config_editing_scripts/get_test_IDS.sh $CONFIGFILE)
        readarray -t CLEAN_FILTER_ARRAY <<<"$GETTESTIDS"

        ../../../hebench_config_tools/config_editing_scripts/split_config_into_single_workloads.sh $CONFIGFILE $RUNTAG\_
        popd

        echo
        echo "Running ${#CLEAN_FILTER_ARRAY[@]} Benchmark(s)"
    
        for i in "${CLEAN_FILTER_ARRAY[@]}"
        do
            if $PERFSTATTEST
            then
                application_perfstat "$i" "REFSEAL" "$(realpath ./temp-folder/$RUNTAG\_$i.yml)" "${benchmarks_to_run[@]}"
            fi
            if $EMONTEST
            then
                application_emon "$i" "REFSEAL" "$(realpath ./temp-folder/$RUNTAG\_$i.yml)" "${benchmarks_to_run[@]}"
            fi
        done

        if $PERFSTATTEST
        then
            cp results-application-level-$RUNTAG/perfstat-logs/REFSEAL/$HEXL_STATUS/application-perfstat-REFSEAL-${HEXL_STATUS}-$STARTTIME.log results-application-level-$RUNTAG/perfstat-logs/REFSEAL/$HEXL_STATUS/application-perfstat-REFSEAL-${HEXL_STATUS}-$STARTTIME.csv
            . ../common-scripts/parse-perfstat-results.sh "results-application-level-$RUNTAG/perfstat-logs/REFSEAL/$HEXL_STATUS/application-perfstat-REFSEAL-${HEXL_STATUS}-$STARTTIME.csv"
        fi
    fi

    echo "Setting Minimum Test Time to back to default (e.g. 0)"
    sed '0,/default_min_test_time/{s/default_min_test_time.*/default_min_test_time: 0/}' -i $CONFIGFILE 

    rm -rf temp-folder
}

loop_refpalisade()
{
    echo -e "\n\nRunning REFERENCE PALISADE BACKEND Benchmarks"
    local INSTALL_PATH=$1
    local benchmarks_to_run=($INSTALL_PATH/bin/test_harness $INSTALL_PATH/lib/libhebench_palisade_backend.so)
    local CONFIGFILE="$PATHTOCONFIGREPO/$REFPALISADEHEBCONFIG"

    mkdir -p temp-folder && rm -rf temp-folder/*
    pushd temp-folder
    if [ ! -f $CONFIGFILE ];
    then
        echo
        echo "----ALERT----: PROVIDED CONFIGURATION FILE NOT FOUND. RUNNING WITH BASE. ----ALERT----"
        echo
        ${benchmarks_to_run[0]} -b ${benchmarks_to_run[1]} --config_file refpalisade_base_config_file.yml --dump
        CONFIGFILE=$(realpath ./refpalisade_base_config_file.yml)
    fi
    popd

    if $PERFORMANCETEST
    then
        echo "Setting Minimum Test Time to sufficient amount to avoid spin/warm-up time"
        sed '0,/default_min_test_time/{s/default_min_test_time.*/default_min_test_time: 5000/}' -i $CONFIGFILE
        application_performance "REFPALISADE" "$CONFIGFILE" "${benchmarks_to_run[@]}"
    fi

    if $PERFSTATTEST || $EMONTEST
    then
        echo "Setting Minimum Test Time to sufficient amount for Hardware Counter capture (it will be killed before completion)"
        sed '0,/default_min_test_time/{s/default_min_test_time.*/default_min_test_time: 500000/}' -i $CONFIGFILE

        pushd temp-folder
        if ! command -v yq &> /dev/null
        then
            ../../../hebench_config_tools/yq_install.sh
            rm install-man-page.sh
            rm yq.1
        fi

        local CLEAN_FILTER_ARRAY=()
        GETTESTIDS=$(../../../hebench_config_tools/config_editing_scripts/get_test_IDS.sh $CONFIGFILE)
        readarray -t CLEAN_FILTER_ARRAY <<<"$GETTESTIDS"

        ../../../hebench_config_tools/config_editing_scripts/split_config_into_single_workloads.sh $CONFIGFILE $RUNTAG\_
        popd

        echo
        echo "Running ${#CLEAN_FILTER_ARRAY[@]} Benchmark(s)"

        for i in "${CLEAN_FILTER_ARRAY[@]}"
        do
            if $PERFSTATTEST
            then
                application_perfstat "$i" "REFPALISADE" "$(realpath ./temp-folder/$RUNTAG\_$i.yml)" "${benchmarks_to_run[@]}"
            fi
            if $EMONTEST
            then
                application_emon "$i" "REFPALISADE" "$(realpath ./temp-folder/$RUNTAG\_$i.yml)" "${benchmarks_to_run[@]}"
            fi
        done

        if $PERFSTATTEST
        then
            cp results-application-level-$RUNTAG/perfstat-logs/REFPALISADE/$HEXL_STATUS/application-perfstat-REFPALISADE-${HEXL_STATUS}-$STARTTIME.log results-application-level-$RUNTAG/perfstat-logs/REFPALISADE/$HEXL_STATUS/application-perfstat-REFPALISADE-${HEXL_STATUS}-$STARTTIME.csv
            . ../common-scripts/parse-perfstat-results.sh "results-application-level-$RUNTAG/perfstat-logs/REFPALISADE/$HEXL_STATUS/application-perfstat-REFPALISADE-${HEXL_STATUS}-$STARTTIME.csv"
        fi
    fi

    echo "Setting Minimum Test Time to back to default (e.g. 0)"
    sed '0,/default_min_test_time/{s/default_min_test_time.*/default_min_test_time: 0/}' -i $CONFIGFILE

    rm -rf temp-folder
}

TEST_REFSEAL=false
TEST_REFPALISADE=false

PS3='ONE AT A TIME, please select the number each of the libraries youd like to test and then Continue to move on (or just "Continue" to select all): '
options=("REFSEAL" "REFPALISADE" "Continue" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "REFSEAL")
            echo "Adding $opt to the set of benchmarks"
            TEST_REFSEAL=true
            ;;
        "REFPALISADE")
            echo "Adding $opt to the set of benchmarks"
            TEST_REFPALISADE=true
            ;;
        "Continue")
            if ! $TEST_REFSEAL && ! $TEST_REFPALISADE 
            then
                echo "You didn't select any benchmarks to run, running all benchmarks by default."
                read -p "Press any key to continue (or CTRL+C to cancel)"
                TEST_REFSEAL=true
                TEST_REFPALISADE=true
            else
                echo "Running the following benchmarks:"
                echo "- REFERENCE SEAL BACKEND ($TEST_REFSEAL)"
                echo "- REFERENCE PALISADE BACKEND ($TEST_REFPALISADE)"
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

REFSEAL_PATH=""
REFPALISADE_PATH=""

if $TEST_REFSEAL
then
    read -e -p 'Please Enter the path to your REFERENCE SEAL BACKEND install directory: ' REFSEAL_PATH
    REFSEAL_PATH=$(realpath $REFSEAL_PATH)
    if [ ! -d "$REFSEAL_PATH" ] || [ ! -f "$REFSEAL_PATH/bin/test_harness" ] || [ ! -f "$REFSEAL_PATH/lib/libhebench_seal_backend.so" ]
    then
        echo "Can not find a REFERENCE SEAL BACKEND installation at the following directory: $REFSEAL_PATH"
        echo "Check that the directory exists and that the REFERENCE SEAL BACKEND is installed correctly"
        exit 1  
    fi
fi

if $TEST_REFPALISADE
then
    read -e -p 'Please Enter the path to your REFERENCE PALISADE BACKEND install directory: ' REFPALISADE_PATH
    REFPALISADE_PATH=$(realpath $REFPALISADE_PATH)
    if [ ! -d "$REFPALISADE_PATH" ] || [ ! -f "$REFPALISADE_PATH/bin/test_harness" ] || [ ! -f "$REFPALISADE_PATH/lib/libhebench_palisade_backend.so" ]
    then
        echo "Can not find a REFERENCE PALISADE BACKEND installation at the following directory: $REFPALISADE_PATH"
        echo "Check that the directory exists and that the REFERENCE PALISADE BACKEND is installed correctly"
        echo "e.g. there should be a bin and lib folder in the above directory"
        exit 1
    fi
fi

read -p 'This will remove any previously run results, press any key to continue (or CTRL+C to exit)'
if [ -z "$RUNTAG" ];
then
    echo
    echo "A 'RUNTAG' must be set to identify this particular run."
    echo "Either run this script with the included 'application-level-runner.sh' script, or set the RUNTAG environment variable before running this script."
    echo 
    exit 1
fi

if $PERFORMANCETEST
then
    PERFOUTPUT="results-application-level-$RUNTAG/performance-logs"
    mkdir -p $PERFOUTPUT
fi
if $PERFSTATTEST
then
    STATOUTPUT="results-application-level-$RUNTAG/perfstat-logs"
    mkdir -p $STATOUTPUT
fi
if $EMONTEST
then
    EMONOUTPUT="results-application-level-$RUNTAG/emon-logs"
    mkdir -p $EMONOUTPUT
    emon -v &> results-application-level-$RUNTAG/emon-logs/emon-v-$STARTTIME.txt
    emon -M &> results-application-level-$RUNTAG/emon-logs/emon-M-$STARTTIME.txt
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
    echo "Either run this script with the included 'application-level-runner.sh' script, or set the HEXL environment variable based on your usage"
    echo
    exit 1
fi

echo "$RUNTAG: $STARTTIME" >> results-application-level-$RUNTAG/STARTED.log
echo "  Process PID: $$" >> results-application-level-$RUNTAG/STARTED.log

if $TEST_REFSEAL
then
    if $PERFORMANCETEST
    then
        mkdir -p $PERFOUTPUT/REFSEAL/$HEXL_STATUS
        rm -rf $PERFOUTPUT/REFSEAL/$HEXL_STATUS/*
    fi
    if $PERFSTATTEST
    then
        mkdir -p $STATOUTPUT/REFSEAL/$HEXL_STATUS
        rm -rf $STATOUTPUT/REFSEAL/$HEXL_STATUS/*
    fi
    if $EMONTEST
    then
        mkdir -p $EMONOUTPUT/REFSEAL/$HEXL_STATUS
        rm -rf $EMONOUTPUT/REFSEAL/$HEXL_STATUS/*
    fi

    loop_refseal "$REFSEAL_PATH"
fi
if $TEST_REFPALISADE
then
    if $PERFORMANCETEST
    then
        mkdir -p $PERFOUTPUT/REFPALISADE/$HEXL_STATUS
        rm -rf $PERFOUTPUT/REFPALISADE/$HEXL_STATUS/*
    fi
    if $PERFSTATTEST
    then
        mkdir -p $STATOUTPUT/REFPALISADE/$HEXL_STATUS
        rm -rf $STATOUTPUT/REFPALISADE/$HEXL_STATUS/*
    fi
    if $EMONTEST
    then
        mkdir -p $EMONOUTPUT/REFPALISADE/$HEXL_STATUS
        rm -rf $EMONOUTPUT/REFPALISADE/$HEXL_STATUS/*
    fi

    loop_refpalisade "$REFPALISADE_PATH"
fi

ENDTIME=$(date +"%m_%d_%Y-%I_%M_%p")
echo "$RUNTAG: $ENDTIME" >> results-application-level-$RUNTAG/FINISHED.log
