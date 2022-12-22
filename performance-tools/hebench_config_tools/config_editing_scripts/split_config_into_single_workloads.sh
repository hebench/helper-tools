#!/bin/bash

set -e

if [[ $# -ne 2 ]]; then
	echo "Script requires the following arguments: INPUT_CONFIG OUTPUT_PREFIX" >&2
	exit 2
fi

TOOL_DIR="$(dirname "$0")"
INPUT_FILE=$1
OUTPUT_PREFIX=$2
echo "Input File: $INPUT_FILE"
echo "Output File(s): ${OUTPUT_PREFIX}ID"

for TEST_ID in $($TOOL_DIR/get_test_IDS.sh ${INPUT_FILE})
do
	$TOOL_DIR/test_selection_command.sh $INPUT_FILE $TEST_ID >> ${OUTPUT_PREFIX}${TEST_ID}.yml
done
