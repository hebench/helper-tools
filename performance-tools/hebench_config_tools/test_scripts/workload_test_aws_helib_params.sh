#!/bin/bash

set -e

if [[ $# -lt 3 ]]; then
        echo "Script requires the following arguments: TEST_HARNESS BACK_END OUTPUT_FOLDER [CONFIG]" >&2
        exit 2
fi

TOOL_DIR="$(dirname "$0")"
TEST_HARNESS_DIR="$(dirname "$1")"
CONFIG_TOOL_DIR=$TOOL_DIR/../config_editing_scripts
TEST_HARNESS=$1
BACK_END=$2
CONFIG=$4
OUTPUT_FOLDER=$3

mkdir -p $OUTPUT_FOLDER/run_logs
mkdir -p $OUTPUT_FOLDER/output_results
mkdir -p $OUTPUT_FOLDER/generated_configs
mkdir -p $OUTPUT_FOLDER/compiled_report

if [[ $# -ne 4 ]]; then
	CONFIG="default_config_$BACK_END.yml"
	$TEST_HARNESS -b $BACK_END -c $CONFIG --dump
fi

MODIFIED_CONFIG=$OUTPUT_FOLDER/generated_configs/$CONFIG
TEST_CONFIG=$OUTPUT_FOLDER/generated_configs/temp.yml

export HEBENCH_MIN_TEST_TIME=1000
export HEBENCH_RAND_SEED=1643220175700488422

export HEBENCH_POLYMOD_DEGREE=0
export HEBENCH_COEFF_MOD_BITS=0

cp $CONFIG $MODIFIED_CONFIG
$CONFIG_TOOL_DIR/config_env_upgrade_script.sh $MODIFIED_CONFIG

export HEBENCH_N=8064
export HEBENCH_POLYMOD_DEGREE=8192
export HEBENCH_COEFF_MOD_BITS=200
export HEBENCH_PLAIN_MOD_BITS=20
export HEBENCH_SCALE_BITS=40
export HEBENCH_SAMPLE_SIZE_0=0
export HEBENCH_SAMPLE_SIZE_1=0

#export HEBENCH_MIN_TEST_TIME=10
#$CONFIG_TOOL_DIR/configurable_env_workload_runner.sh $TEST_HARNESS $BACK_END $MODIFIED_CONFIG $OUTPUT_FOLDER 2,3 BGV Latency,Offline

#export HEBENCH_MIN_TEST_TIME=1000
#$CONFIG_TOOL_DIR/configurable_env_workload_runner.sh $TEST_HARNESS $BACK_END $MODIFIED_CONFIG $OUTPUT_FOLDER 4 BGV Latency,Offline

export HEBENCH_N=3456
export HEBENCH_POLYMOD_DEGREE=16384
export HEBENCH_COEFF_MOD_BITS=299
$CONFIG_TOOL_DIR/configurable_env_workload_runner.sh $TEST_HARNESS $BACK_END $MODIFIED_CONFIG $OUTPUT_FOLDER 2,3,4 CKKS Latency,Offline

export HEBENCH_SAMPLE_SIZE_0=0
export HEBENCH_SAMPLE_SIZE_1=0

#export HEBENCH_ROWS_M0=8192
#export HEBENCH_COLS_M0=100
#export HEBENCH_COLS_M1=10
#$CONFIG_TOOL_DIR/configurable_env_workload_runner.sh $TEST_HARNESS $BACK_END $MODIFIED_CONFIG $OUTPUT_FOLDER 1 CKKS,BGV Latency 0

export HEBENCH_N=16
export HEBENCH_POLYMOD_DEGREE=32768
export HEBENCH_COEFF_MOD_BITS=613
export HEBENCH_SAMPLE_SIZE_2=1152
$CONFIG_TOOL_DIR/configurable_env_workload_runner.sh $TEST_HARNESS $BACK_END $MODIFIED_CONFIG $OUTPUT_FOLDER 6 CKKS Latency,Offline

ls -d $PWD/$OUTPUT_FOLDER/output_results/*-report.csv | tee $OUTPUT_FOLDER/output_results/all_files.txt

$TEST_HARNESS_DIR/../report_gen/report_compiler/report_compiler $OUTPUT_FOLDER/output_results/all_files.txt
cp $OUTPUT_FOLDER/output_results/all_files_overview.csv $OUTPUT_FOLDER/compiled_report/compiled_report.csv
