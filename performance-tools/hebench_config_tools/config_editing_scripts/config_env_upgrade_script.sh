#!/bin/bash

set -e

CONFIG=$1

#setup number of threads in file
yq e -i '(.*[].*[] | select(.name == "NumThreads")) .value.from="$HEBENCH_MIN_NUM_THREADS"' $CONFIG
yq e -i '(.*[].*[] | select(.name == "NumThreads")) .value.to="$HEBENCH_MAX_NUM_THREADS"' $CONFIG
yq e -i '(.*[].*[] | select(.name == "NumThreads")) .value.step="$HEBENCH_THREAD_STEP"' $CONFIG

#POLYMOD
yq e -i '(.*[].*[] | select(.name == "PolyModulusDegree")) .value.from="$HEBENCH_POLYMOD_DEGREE"' $CONFIG
yq e -i '(.*[].*[] | select(.name == "PolyModulusDegree")) .value.to="$HEBENCH_POLYMOD_DEGREE"' $CONFIG

#COEFF MOD BITS
yq e -i '(.*[].*[] | select(.name == "CoefficientModulusBits")) .value.from="$HEBENCH_COEFF_MOD_BITS"' $CONFIG
yq e -i '(.*[].*[] | select(.name == "CoefficientModulusBits")) .value.to="$HEBENCH_COEFF_MOD_BITS"' $CONFIG

#PLAIN MOD BITS
yq e -i '(.*[].*[] | select(.name == "PlainModulusBits")) .value.from="$HEBENCH_PLAIN_MOD_BITS"' $CONFIG
yq e -i '(.*[].*[] | select(.name == "PlainModulusBits")) .value.to="$HEBENCH_PLAIN_MOD_BITS"' $CONFIG

#MULTI_DEPTH
yq e -i '(.*[].*[] | select(.name == "MultiplicativeDepth")) .value.from="$HEBENCH_MULT_DEPTH"' $CONFIG
yq e -i '(.*[].*[] | select(.name == "MultiplicativeDepth")) .value.to="$HEBENCH_MULT_DEPTH"' $CONFIG

#PLAIN MOD BITS
yq e -i '(.*[].*[] | select(.name == "ScaleBits")) .value.from="$HEBENCH_SCALE_BITS"' $CONFIG
yq e -i '(.*[].*[] | select(.name == "ScaleBits")) .value.to="$HEBENCH_SCALE_BITS"' $CONFIG

#GLOBAL
yq e -i '(.default_min_test_time="$HEBENCH_MIN_TEST_TIME"' $CONFIG
yq e -i '(.random_seed="$HEBENCH_RAND_SEED"' $CONFIG

#Wordload Specific
yq e -i '(.*[].*[] | select(.name == "n")) .value.from="$HEBENCH_N"' $CONFIG
yq e -i '(.*[].*[] | select(.name == "n")) .value.to="$HEBENCH_N"' $CONFIG
yq e -i '(.*[].*[] | select(.name == "rows_M0")) .value.from="$HEBENCH_ROWS_M0"' $CONFIG
yq e -i '(.*[].*[] | select(.name == "rows_M0")) .value.to="$HEBENCH_ROWS_M0"' $CONFIG
yq e -i '(.*[].*[] | select(.name == "cols_M0")) .value.from="$HEBENCH_COLS_M0"' $CONFIG
yq e -i '(.*[].*[] | select(.name == "cols_M0")) .value.to="$HEBENCH_COLS_M0"' $CONFIG
yq e -i '(.*[].*[] | select(.name == "cols_M1")) .value.from="$HEBENCH_COLS_M1"' $CONFIG
yq e -i '(.*[].*[] | select(.name == "cols_M1")) .value.to="$HEBENCH_COLS_M1"' $CONFIG

#Add sample size variables
yq e -i '(.*[].default_sample_sizes.0="$HEBENCH_SAMPLE_SIZE_0"' $CONFIG
yq e -i '(.*[].default_sample_sizes.1="$HEBENCH_SAMPLE_SIZE_1"' $CONFIG
yq e -i '(.*[].default_sample_sizes.2="$HEBENCH_SAMPLE_SIZE_2"' $CONFIG
yq e -i '(.*[].default_sample_sizes.3="$HEBENCH_SAMPLE_SIZE_3"' $CONFIG

yq e -i '(.*[].dataset) =~' $CONFIG