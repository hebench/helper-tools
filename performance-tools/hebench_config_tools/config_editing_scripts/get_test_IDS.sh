#!/bin/bash

set -e

if [[ $# -ne 1 ]]; then
	echo "Script requires the following arguments: INPUT_CONFIG" >&2
	exit 2
fi

INPUT_FILE=$1

yq e '.benchmark[].ID' $INPUT_FILE
