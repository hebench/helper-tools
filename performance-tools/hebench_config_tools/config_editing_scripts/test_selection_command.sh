#!/bin/bash

set -e

if [[ $# -ne 2 ]]; then
	        echo "Script requires the following arguments: INPUT_CONFIG TEST_ID" >&2
		        exit 2
fi

INPUT_FILE=$1
TEST_ID=$2

CMD="yq e '(.*[] | select(.ID != "'"'$TEST_ID'"'")) |= del(.[]) | del(.. | select(tag == "'"'!!map'"'" and length == 0))' $INPUT_FILE"
eval $CMD
