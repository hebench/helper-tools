#!/bin/bash

echo "Starting Performance Test"
#CMD line option: [CLONE REPOS] [RUN NAME]
#########################RUN CONFIG############################################

#Compilers to test
COMPILERS+=('gcc-9 g++-9')
COMPILERS+=('gcc-10 g++-10')

#SEAL Tests
SEAL_TEST_SCRIPTS+=("ckks/ckks_workload_test_aws_seal_params")
SEAL_TEST_SCRIPTS+=("ckks/ckks_threading_aws_seal_params_noMM")
		  
#PALISADE Tests
PALISADE_TEST_SCRIPTS+=("ckks/ckks_workload_test_aws_palisade")
PALISADE_TEST_SCRIPTS+=("ckks/ckks_threading_aws_palisade_noMM")

#HELib Tests
HELIB_TEST_SCRIPTS+=("ckks/ckks_workload_test_aws_helib_params")
HELIB_TEST_SCRIPTS+=("ckks/ckks_threading_aws_helib_params_noMM")

#HEXL OPTIONS TO TEST
HEXL_OPT+=("OFF")
HEXL_OPT+=("ON")

#NTL OPTIONS
NTL_OPT+=("OFF")
#NTL_OPT+=("ON")

#OPENMP OPTS
OPENMP_OPT+=("OFF")
#OPENMP_OPT+=("ON")

#THREADING
HELIB_THREADING_OPT+=("OFF")
#HELIB_THREADING_OPT+=("ON")

###################################################################
if [ -z "$1" ]
   then
     PULL_OPT=ON
   else
    PULL_OPT="$1"
fi

if [ -z "$2" ]
   then
     RUNTAG_OPT="default"
   else
    RUNTAG_OPT="$2"
fi

if [ $PULL_OPT = "ON" ]
  then
   ./clone_test_repos.sh
fi

#seal tests // Script arguments: HEXL(ON,*OFF) [COMPILER_C] [COMPILER_CXX]
if [[ -v SEAL_TEST_SCRIPTS[@] ]]
then
	for ((h = 0; h < ${#HEXL_OPT[@]}; h++))
	do
		for ((i = 0; i < ${#COMPILERS[@]}; i++))
		do
		   ./setup_seal.sh "${HEXL_OPT[$h]}" ${COMPILERS[$i]}
		   COMP_STR="${COMPILERS[$i]// /_}"
		   for ((j = 0; j < ${#SEAL_TEST_SCRIPTS[@]}; j++))
		   do
			 echo "Running Test: ${RUNTAG_OPT}_HEXL-${HEXL_OPT[$h]}_${COMP_STR}"
			 ./run_seal_tests.sh ${RUNTAG_OPT}_HEXL-${HEXL_OPT[$h]}_${COMP_STR} "${SEAL_TEST_SCRIPTS[j]}"
		   done
		done
	done
fi


#PALISADE tests // Script arguments: [HEXL(ON,*OFF)] [COMPILER_C] [COMPILER_CXX] [NTL] [OPENMP]
if [[ -v PALISADE_TEST_SCRIPTS[@] ]]
then
	for ((h = 0; h < ${#HEXL_OPT[@]}; h++))
	do
		for ((i = 0; i < ${#COMPILERS[@]}; i++))
		do
			for ((j = 0; j < ${#NTL_OPT[@]}; j++))
			do
				for ((k = 0; k < ${#OPENMP_OPT[@]}; k++))
				do
				   ./setup_palisade.sh "${HEXL_OPT[$h]}" ${COMPILERS[$i]} "${NTL_OPT[$j]}" "${OPENMP_OPT[$k]}"
				   COMP_STR="${COMPILERS[$i]// /_}"
				   for ((j = 0; j < ${#PALISADE_TEST_SCRIPTS[@]}; j++))
				   do
					 ./run_palisade_tests.sh ${RUNTAG_OPT}_HEXL-"${HEXL_OPT[$h]}"_${COMP_STR}_NTL-"${NTL_OPT[$j]}"_OPENMP-"${OPENMP_OPT[$k]}" "${PALISADE_TEST_SCRIPTS[j]}"
				   done
			   done
		   done
		done
	done
fi

#HELib tests // Script arguments: [HEXL(ON,*OFF)] [COMPILER_C] [COMPILER_CXX] [THREADING]
if [[ -v HELIB_TEST_SCRIPTS[@] ]]
then
	for ((h = 0; h < ${#HEXL_OPT[@]}; h++))
	do
		for ((i = 0; i < ${#COMPILERS[@]}; i++))
		do
			for ((j = 0; j < ${#HELIB_THREADING_OPT[@]}; j++))
			do
				   ./setup_helib.sh "${HEXL_OPT[$h]}" ${COMPILERS[$i]} "${HELIB_THREADING_OPT[$j]}"
				   COMP_STR="${COMPILERS[$i]// /_}"
				   for ((j = 0; j < ${#HELIB_TEST_SCRIPTS[@]}; j++))
				   do
					 ./run_helib_tests.sh ${RUNTAG_OPT}_HEXL-"${HEXL_OPT[$h]}"_${COMP_STR}_THREADING-"${HELIB_THREADING_OPT[$j]}" "${HELIB_TEST_SCRIPTS[j]}"
				   done
		   done
		done
	done
fi


mkdir ./test_results/collected_reports
cp -r ./test_results/*/compiled_report/*.csv ./test_results/collected_reports/.
echo "ALL TESTS COMPLETE"

