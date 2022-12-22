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

ssh-copy-id "$USER_ID@$REMOTE_ADDRESS"
scp hebench_test.tar.gz $USER_ID@$REMOTE_ADDRESS:.
ssh -t $USER_ID@$REMOTE_ADDRESS "rm -rf ~/hebench_test_setup; tar -xvf ~/hebench_test.tar.gz"
ssh -t $USER_ID@$REMOTE_ADDRESS "source ~/.bashrc; cd ~/hebench_test_setup; ~/hebench_test_setup/setup_dependencies_all.sh; export https_proxy=$HTTP_PROXY; ./helper-tools/performance-tools/hebench_config_tools/yq_install.sh;"
scp $TEST_SCRIPT $USER_ID@$REMOTE_ADDRESS:~/hebench_test_setup/$TEST_SCRIPT
ssh $USER_ID@$REMOTE_ADDRESS "echo 'Begin Test'; cd ~/hebench_test_setup; git config --global http.proxy $HTTP_PROXY; (nohup ./$TEST_SCRIPT OFF $SYSTEM_NAME) 1>$SYSTEM_NAME.log 2>/dev/null &"
ssh $USER_ID@$REMOTE_ADDRESS "cd ~/hebench_test_setup; tail -f $SYSTEM_NAME.log | sed '/^ALL TESTS COMPLETE$/ q'"
ssh $USER_ID@$REMOTE_ADDRESS "cd ~/hebench_test_setup; tar -czvf $SYSTEM_NAME.tar.gz test_results"
scp $USER_ID@$REMOTE_ADDRESS:hebench_test_setup/$SYSTEM_NAME.tar.gz .

