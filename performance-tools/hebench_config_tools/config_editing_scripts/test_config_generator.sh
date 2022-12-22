#!/bin/bash

set -e

if [[ $# -lt 2 ]]; then
        echo "Script requires the following arguments: CONFIG RESULT_CONFIG [TEST_TYPE] [SCHEME] [CATEGORY] [OTHER] [SECURITY] [CIPHER_FLAGS]" >&2
		echo "ALL can be used as a wildcard value, Optional values must be provided in order" >&2
        exit 2
fi
CONFIG=$1
RESULT_CONFIG=$2

if [ -z "$3" ]
  then
    TEST_TYPE=ALL
  else
    TEST_TYPE="$3"
fi
if [ -z "$4" ]
  then
    SCHEME=ALL
  else
    SCHEME="$4"
fi
if [ -z "$5" ]
  then
    CATEGORY=ALL
  else
    CATEGORY="$5"
fi
if [ -z "$6" ]
  then
    OTHER=ALL
  else
    OTHER="$6"
fi
if [ -z "$7" ]
  then
    SECURITY=ALL
  else
    SECURITY="$7"	
fi
if [ -z "$8" ]
  then
    CIPHER_FLAGS=ALL
  else
    CIPHER_FLAGS="$8"
fi

if [ "$TEST_TYPE" = ALL ]
then
	TEST_TYPE=*
fi
if [ "$SCHEME" = ALL ]
then
	SCHEME=*
fi
if [ "$CATEGORY" = ALL ]
then
	CATEGORY=*
fi
if [ "$OTHER" = ALL ]
then
	OTHER=*
fi
if [ "$SECURITY" = ALL ]
then
	SECURITY=*
fi
if [ "$CIPHER_FLAGS" = ALL ]
then
	CIPHER_FLAGS=*
fi

EVAL_STR='(.*[] | select(.description.workload != "'$TEST_TYPE'" or .description.scheme != "'$SCHEME'" or .description.category != "'$CATEGORY'" or .description.other != "'$OTHER'" or .description.security != "'${SECURITY}'" or .description.cipher_flags != "'$CIPHER_FLAGS'")) |= del(.[]) | del(.. | select(tag == "!!map" and length == 0))'
CMD="yq e '"$EVAL_STR"' $CONFIG | tee $RESULT_CONFIG"
eval $CMD

