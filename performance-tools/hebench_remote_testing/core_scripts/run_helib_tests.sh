
LIB_CONFIG=$1

TEST_SCRIPTS=$2
	      
TEST_HARNESS="./reference-helib-backend/build/third-party/frontend/frontend-build/test_harness/test_harness"
BACK_END="./reference-helib-backend/build/libhebench_helib_backend.so"
RESULT_FOLDER="test_results"
TEST_SCRIPT_FOLDER="./helper-tools/performance-tools/hebench_config_tools/test_scripts"

mkdir $RESULT_FOLDER

for TEST in $TEST_SCRIPTS
do
	rm -rf $RESULT_FOLDER/${LIB_CONFIG}_$(basename ${TEST})
	$TEST_SCRIPT_FOLDER/$TEST.sh $TEST_HARNESS $BACK_END $RESULT_FOLDER/${LIB_CONFIG}_$(basename ${TEST})
	mv $RESULT_FOLDER/${LIB_CONFIG}_$(basename ${TEST})/compiled_report/compiled_report.csv $RESULT_FOLDER/${LIB_CONFIG}_$(basename ${TEST})/compiled_report/${LIB_CONFIG}_$(basename ${TEST})_report.csv
done
