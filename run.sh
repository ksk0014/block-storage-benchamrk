#!/bin/sh

#-------------------------------------------------------------------------------
#  Usage: block storage perf benchmark
#  Authors: ksk0014<kandkang0014@gmail.com>
#  Date: 2017.03.13
#-------------------------------------------------------------------------------

function usage() {
    cat << EOF
Usage: run.sh

Auto block storage perf test:
    The tool can help you to test block storage performance automatically.
    Please run such as bash +x run.sh

Options:
  --help | -h
    Print usage information.
  --cloud [cloud_name] | -c [cloud_name]
    Cloud where the benchmarks are run. default XXX
  --benchmarks [options] | -b [options]
    A comma separated list of benchmarks or benchmark sets to run such as --benchmarks latency,iops,throughput,stability,. 
    To see the full list, run ./run.sh --help
  --machine_quota [machine_quota] | -m [machine_quota]
    Type of machine to provision if pre-provisioned machines are not used. 
  --series [series_name] | -s [series_name]
    This flag allows you to set series name that fio result upload to at the benchmark platform.
  --report_ver [report_name] | -r [report_name]
    This flag set fio result name, such as --report_ver ssd.
  --disk_type [options] | -d [options]
    Disk type what the benchmarks create, such as --disk_type cds1_ssd 
  --targets [device_name] | -t [device_name]
    Benchmark device name, such as --targets sdi,sdj.
  --upload [bool] | -u [bool]
    Upload result to benchmark platfrom  
EOF
    exit 0
}

set -o xtrace

CLOUD="XXX"
MACHINE_QUOTA=""
BENCHMARK_OPTIONS=""
SERIES_NAME=""
REPORT_VERSION=""
DISK_TYPE=""
TARGETS=""
ATTACH_MACHINE="local"
UPLOAD="false"
while [ $# -gt 0 ]; do
  case "$1" in
    -h| --help) usage ;;
    -c| --cloud) shift; CLOUD=$1 ;;
    -b| --benchmarks) shift; BENCHMARK_OPTIONS=$1 ;;
    -m| --machine_quota) shift; MACHINE_QUOTA=$1 ;; 
    -s| --series) shift; SERIES_NAME=$1 ;;
    -r| --report_ver) shift; REPORT_VERSION=$1 ;;
    -d| --disk_type) shift; DISK_TYPE=$1 ;;
    -t| --targets) shift; TARGETS=$1 ;;
    -u| --upload) shift; UPLOAD=$1 ;;
    *) shift ;;
  esac
  shift
done

# not implenment
## prepare vm 
#if [[ $MACHINE_QUOTA != "" ]];then
#    ATTACH_MACHINE=`sh prepare_resource.sh --cloud $CLOUD --machine_quota $MACHINE_QUOTA`
#fi
#
## prepare disk
#if [[ $DISK_TYPE != "" ]];then
#    TARGETS=`sh prepare_resource.sh --cloud $CLOUD --disk_type $DISK_TYPE --attach_machine $ATTACH_MACHINE`
#fi

# sgart perf benchmark test
if [[ $BENCHMARK_OPTIONS != "" ]];then
    nohup sh run_benchmark.sh --cloud $CLOUD --targets $TARGETS --benchmarks $BENCHMARK_OPTIONS --series $SERIES_NAME --report_ver $REPORT_VERSION  &
fi

if [[ $UPLOAD == "true" ]];then
    python benchmark.py -mdetail --append result_${CLOUD}_${TARGETS}_${SERIES_NAME}*
    report_day=`date +%Y-%m-%d-%H`
    mkdir -p $report_day
    mv ${CLOUD}_${TARGETS}_${SERIES_NAME}* result_${CLOUD}_${TARGETS}_${SERIES_NAME}* nohup.out ${report_day}/
fi
