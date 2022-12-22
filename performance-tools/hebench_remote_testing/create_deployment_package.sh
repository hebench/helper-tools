set -e

mkdir hebench_test_setup
cd hebench_test_setup
cp ../core_scripts/* .
./clone_test_repos.sh
cd ..
tar -czvf hebench_test.tar.gz hebench_test_setup
rm -rf hebench_test_setup

