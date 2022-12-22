#!/bin/bash

set -e

if [[ $# -ne 3 ]]; then
	echo "Script requires the following arguments: MIN_THREADS MAX_THREADS THREAD_STEP" >&2
	exit 2
fi

echo "minimum threads:" $1
echo "maximum threads:" $2
echo "thread step: " $3

export HEBENCH_MIN_NUM_THREADS=$1
export HEBENCH_MAX_NUM_THREADS=$2
export HEBENCH_THREAD_STEP=$3
