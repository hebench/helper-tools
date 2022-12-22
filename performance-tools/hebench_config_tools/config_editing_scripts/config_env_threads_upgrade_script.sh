#!/bin/bash

set -e

CONFIG=$1

#setup number of threads in file
yq e -i '(.*[].*[] | select(.name == "NumThreads")) .value.from="$HEBENCH_MIN_NUM_THREADS"' $CONFIG
yq e -i '(.*[].*[] | select(.name == "NumThreads")) .value.to="$HEBENCH_MAX_NUM_THREADS"' $CONFIG
yq e -i '(.*[].*[] | select(.name == "NumThreads")) .value.step="$HEBENCH_THREAD_STEP"' $CONFIG
yq e -i '(.*[].dataset) =~' $CONFIG
