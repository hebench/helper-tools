#!/bin/bash

set -e

if [[ $# -ne 5 ]]; then
        echo "Script requires the following arguments: TEST_HARNESS BACK_END CONFIG_FILE OUTPUT_FILE OUTPUT_FOLDER" >&2
        exit 2
fi

TEST_HARNESS=$1
BACK_END=$2
CONFIG_FILE=$3
RUN_NAME=$4
OUTPUT_FOLDER=$5

if [ -z ${HEBENCH_POLYMOD_DEGREE+x} ]; then export HEBENCH_POLYMOD_DEGREE=0; echo "HEBENCH_POLYMOD_DEGREE is set to '$HEBENCH_POLYMOD_DEGREE'"; fi
if [ -z ${HEBENCH_MIN_TEST_TIME+x} ]; then export HEBENCH_MIN_TEST_TIME=0; echo "HEBENCH_MIN_TEST_TIME is set to '$HEBENCH_MIN_TEST_TIME'"; fi
if [ -z ${HEBENCH_MIN_NUM_THREADS+x} ]; then export HEBENCH_MIN_NUM_THREADS=0; echo "HEBENCH_MIN_NUM_THREADS is set to '$HEBENCH_MIN_NUM_THREADS'"; fi
if [ -z ${HEBENCH_MAX_NUM_THREADS+x} ]; then export HEBENCH_MAX_NUM_THREADS=0; echo "HEBENCH_MAX_NUM_THREADS is set to '$HEBENCH_MAX_NUM_THREADS'"; fi
if [ -z ${HEBENCH_THREAD_STEP+x} ]; then export HEBENCH_THREAD_STEP=0; echo "HEBENCH_THREAD_STEP is set to '$HEBENCH_THREAD_STEP'"; fi
if [ -z ${HEBENCH_RAND_SEED+x} ]; then export HEBENCH_RAND_SEED=0; echo "HEBENCH_RAND_SEED is set to '$HEBENCH_RAND_SEED'"; fi
if [ -z ${HEBENCH_COEFF_MOD_BITS+x} ]; then export HEBENCH_COEFF_MOD_BITS=0; echo "HEBENCH_COEFF_MOD_BITS is set to '$HEBENCH_COEFF_MOD_BITS'"; fi
if [ -z ${HEBENCH_PLAIN_MOD_BITS+x} ]; then export HEBENCH_PLAIN_MOD_BITS=0; echo "HEBENCH_PLAIN_MOD_BITS is set to '$HEBENCH_PLAIN_MOD_BITS'"; fi
if [ -z ${HEBENCH_MULT_DEPTH+x} ]; then export HEBENCH_MULT_DEPTH=0; echo "HEBENCH_MULT_DEPTH is set to '$HEBENCH_MULT_DEPTH'"; fi
if [ -z ${HEBENCH_SAMPLE_SIZE_0+x} ]; then export HEBENCH_SAMPLE_SIZE_0=0; echo "HEBENCH_SAMPLE_SIZE_0 is set to '$HEBENCH_SAMPLE_SIZE_0'"; fi
if [ -z ${HEBENCH_SAMPLE_SIZE_1+x} ]; then export HEBENCH_SAMPLE_SIZE_1=0; echo "HEBENCH_SAMPLE_SIZE_1 is set to '$HEBENCH_SAMPLE_SIZE_1'"; fi
if [ -z ${HEBENCH_SAMPLE_SIZE_2+x} ]; then export HEBENCH_SAMPLE_SIZE_2=0; echo "HEBENCH_SAMPLE_SIZE_2 is set to '$HEBENCH_SAMPLE_SIZE_2'"; fi
if [ -z ${HEBENCH_SAMPLE_SIZE_3+x} ]; then export HEBENCH_SAMPLE_SIZE_3=0; echo "HEBENCH_SAMPLE_SIZE_3 is set to '$HEBENCH_SAMPLE_SIZE_3'"; fi
if [ -z ${HEBENCH_N+x} ]; then export HEBENCH_N=0; echo "HEBENCH_N is set to '$HEBENCH_N'"; fi
if [ -z ${HEBENCH_ROWS_M0+x} ]; then export HEBENCH_ROWS_M0=0; echo "HEBENCH_ROWS_M0 is set to '$HEBENCH_ROWS_M0'"; fi
if [ -z ${HEBENCH_COLS_M0+x} ]; then export HEBENCH_COLS_M0=0; echo "HEBENCH_COLS_M0 is set to '$HEBENCH_COLS_M0'"; fi
if [ -z ${HEBENCH_COLS_M1+x} ]; then export HEBENCH_COLS_M1=0; echo "HEBENCH_COLS_M1 is set to '$HEBENCH_COLS_M1'"; fi

$TEST_HARNESS -b $BACK_END -c $CONFIG_FILE --single_path_report --output_dir $OUTPUT_FOLDER/output_results | tee -a $RUN_NAME