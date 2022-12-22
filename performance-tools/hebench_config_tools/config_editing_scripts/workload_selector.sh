#!/bin/bash

set -e

if [[ $# -ne 4 ]]; then
        echo "Script requires the following arguments: TEST_TYPE SCHEME TEST_HARNESS BACKEND CONFIG RESULT_CONFIG" >&2
        exit 2
fi

TEST_TYPE=$1
SCHEME=$2
TEST_HARNESS=$3
BACKEND=$4
CONFIG=$5

for TEST in ${TEST_TYPE//,/ }
do
	yq e '(.*[] | select(.description.workload != "'$TEST'" or .description.scheme != "'$SCHEME'")) |= del(.[]) | del(.. | select(tag == "!!map" and length == 0))' $CONFIG |tee ./configurator_tmp.yml
	$TEST_HARNESS -b $BACKEND -c ./configurator_tmp.yml
done
