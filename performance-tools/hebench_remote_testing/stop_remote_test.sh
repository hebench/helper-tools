#!/bin/bash

set -e

if [[ $# -ne 4 ]]; then
	echo "Script requires the following arguments: USER_ID REMOTE_IP_ADDRESS RUN_NAME TEST_SCRIPT" >&2
	exit 2
fi

USER_ID=$1
REMOTE_ADDRESS=$2
SYSTEM_NAME=$3
TEST_SCRIPT=$4

WATCH_STR="ALL TESTS COMPLETE"

ssh -t $USER_ID@$REMOTE_ADDRESS "pkill -u $USER_ID"
