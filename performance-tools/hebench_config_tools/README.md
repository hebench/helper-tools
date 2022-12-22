# HEBench commandline config editing scripts

This repo contains scripts built around the yq tool to aid with editing/modifying hebench scripts quickly.

## yq installation
The "yq_install.sh" script will install the 4.26.1 version of yq. The scripts provided have been tested with this version.

## Current tools

split_config_into_single_workloads.sh : Will take an input config file and parse it into seperate configs for each test ID. 
      Script requires the following arguments: INPUT_CONFIG OUTPUT_PREFIX

config_env_threads_upgrade_script.sh : Will replace test thread parameters if present with environment variables to allow for easier commandline/script manipulation and control. 

