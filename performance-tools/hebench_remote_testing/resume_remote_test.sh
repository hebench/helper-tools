#!/bin/bash

set -e

if [[ $# -ne 3 ]]; then
	echo "Script requires the following arguments: USER_ID REMOTE_IP_ADDRESS RUN_NAME" >&2
	exit 2
fi

USER_ID=$1
REMOTE_ADDRESS=$2
SYSTEM_NAME=$3

WATCH_STR="ALL TESTS COMPLETE"

ssh $USER_ID@$REMOTE_ADDRESS "cd ~/hebench_test_setup; tail -f $SYSTEM_NAME.log | sed '/^ALL TESTS COMPLETE$/ q'"
ssh $USER_ID@$REMOTE_ADDRESS "cd ~/hebench_test_setup; tar -czvf $SYSTEM_NAME.tar.gz test_results"
scp $USER_ID@$REMOTE_ADDRESS:hebench_test_setup/$SYSTEM_NAME.tar.gz .

