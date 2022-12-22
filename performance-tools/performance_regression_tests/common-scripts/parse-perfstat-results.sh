#!/bin/bash

set -e

LOGFILE=$1

if [ -z "$LOGFILE" ] || [ -z "$CLEAN_FILTER_ARRAY" ]
then
    echo "The path to the perfstat logfile must be passed into this script."
    echo "Also, the benchmark filter used for the logfile must be set already from the library-level-test.sh script"
    echo
    exit 1
fi

grep -hnr "instructions\|seconds time elapsed" $LOGFILE | awk -F ' ' '{print $2}' > temp.txt
echo "benchmark_filter,instructions_ran,seconds_elapsed,instructions_per_second" > $LOGFILE

ARR_COUNTER=0
while mapfile -t -n 2 ary && ((${#ary[@]}))
do
    var0=$(sed 's/,//g' <<<"${ary[0]}") 
    var1=$(printf "%.0f" "${ary[1]}")
    
    echo "${CLEAN_FILTER_ARRAY[$ARR_COUNTER]},$var0,$(($var1 + 1)),$(($var0 / ($var1 + 1)))" >> $LOGFILE

    ARR_COUNTER=$((ARR_COUNTER+1))
done < temp.txt
rm temp.txt

