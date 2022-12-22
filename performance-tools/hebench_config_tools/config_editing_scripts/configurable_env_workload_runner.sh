#!/bin/bash

set -e

if [[ $# -lt 4 ]]; then
		echo "This script is used to run tests from a config file filtered by the specified variables and upgraded to use standard ENV variables"
        echo "Script requires the following arguments: TEST_HARNESS BACKEND TEST_TYPE CONFIG OUTPUT_FOLDER [TEST_TYPE] [SCHEME] [CATEGORY] [OTHER] [SECURITY] [CIPHER_FLAGS]" >&2
        exit 2
fi

TOOL_DIR="$(dirname "$0")"
TEST_HARNESS=$1
BACKEND=$2
CONFIG="$3"
OUTPUT_FOLDER="$4"
if [ -z "$5" ]
  then
    TEST_TYPE=ALL
  else
    TEST_TYPE="$5"
fi
if [ -z "$6" ]
  then
    SCHEME_TYPE=ALL
  else
    SCHEME_TYPE="$6"
fi
if [ -z "$7" ]
  then
    CATEGORY_TYPE=ALL
  else
    CATEGORY_TYPE="$7"
fi
if [ -z "$8" ]
  then
    OTHER_TYPE=ALL
  else
    OTHER_TYPE="$8"
fi
if [ -z "$9" ]
  then
    SECURITY_TYPE=ALL
  else
    SECURITY_TYPE="$9"	
fi
if [ -z "${10}" ]
  then
    CIPHER_FLAGS_TYPE=ALL
  else
    CIPHER_FLAGS_TYPE="${10}"
fi

mkdir -p $OUTPUT_FOLDER
mkdir -p $OUTPUT_FOLDER/output_results
mkdir -p $OUTPUT_FOLDER/generated_configs

IFS_BACKUP="$IFS"
IFS=","

for TEST in $TEST_TYPE
do
	for CATEGORY in $CATEGORY_TYPE
	do
		for SCHEME in $SCHEME_TYPE
		do
			for OTHER in $OTHER_TYPE
			do
				for SECURITY in $SECURITY_TYPE
				do
					for CIPHER_FLAGS in $CIPHER_FLAGS_TYPE
					do
						GEN_CONFIG_FILE_NAME=$OUTPUT_FOLDER/generated_configs/generated_"${TEST}"_"${CATEGORY}"_"${SCHEME}"_"${OTHER}"_"${SECURITY}"_"${CIPHER_FLAGS}".yml
						GEN_CONFIG_FILE_NAME="${GEN_CONFIG_FILE_NAME// /_}"
						$TOOL_DIR/test_config_generator.sh $CONFIG $GEN_CONFIG_FILE_NAME "$TEST" "$SCHEME" "$CATEGORY" "$OTHER" "$SECURITY" "$CIPHER_FLAGS"
						$TOOL_DIR/run_config.sh $TEST_HARNESS $BACKEND $GEN_CONFIG_FILE_NAME $OUTPUT_FOLDER/run_logs/run_"${TEST}"_"${CATEGORY}"_"${SCHEME}"_"${OTHER}"_"${SECURITY}"_"${CIPHER_FLAGS}".log $OUTPUT_FOLDER
					done
				done
			done
		done
	done
done