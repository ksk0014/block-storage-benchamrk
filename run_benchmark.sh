#!/bin/sh

#-------------------------------------------------------------------------------
#  Usage: fio start scripts
#  Authors: ksk0014<kandkang0014@gmail.com>
#  Date: 2017.03.13
#-------------------------------------------------------------------------------

source ./util.sh

function usage() {
    cat << EOF
Usage: run_benchmark.sh

Auto exec perf test:
    The tool can help you to test block storage performance automatically.
    Please run such as bash +x run_benchmark.sh

Options:
  --help | -h
    Print usage information.
  --cloud [cloud_name] | -c [cloud_name]
    Cloud where the benchmarks are run. default Baidu
  --volume type [volume_type] | -vt [volume_type]
  --volume size [volume_size] | -vs [volume_size]
  --volume id   [volume_id] | -vi [volume_id]
  --cpu [cpu] | -cp [cpu] 
  --mem [mem_size] | -m [mem_size]
  --os [os_name] | -o [os_name]
  --region [region_name] | -r [region_name]
  --az [az_name] | -a [az_name]
  --benchmarks [options] | -b [options]
    A comma separated list of benchmarks or benchmark sets to run such as --benchmarks latency,iops,throughput,stabily,.
    To see the full list, run ./run_benchmark.sh --help
  --series [series_name] | -s [series_name]
    This flag allows you to set series name that fio result upload to at the benchmark platform.
  --targets [device_name] | -t [device_name]
    Benchmark device name, such as --targets sdi,sdj.
EOF
    exit 0
}

function add_header() {
    
    volume_type=$1
    volume_size=$2
    volume_id=$3
    os=`/usr/bin/lsb_release -a |grep "Des"|sed 's@^.*on:@@g'|sed s/[[:space:]]//g`
    Total=$(cat /proc/meminfo |grep 'MemTotal' |awk -F : '{print $2/1048576+0.5}' |sed 's/^[ \t]*//g')
    mem=$(echo $Total| cut -d"." -f1)
    cpu=$(grep 'processor' /proc/cpuinfo |sort |uniq |wc -l)
    cloud=$4
    region_az=$5
    time=$6
    version=${cloud}_${region_az}_${volume_type}_${time}
    cat << START_HEAD
[head]
version_name:${version}
tag:${cloud}_${region_az}
report_description:${version}
volume_type:${volume_type}
volume_size:${volume_size}
volume_id:${volume_id}
timestamps:${time}
cpu:${cpu}
mem:${mem}
os:${os}
region_az:${region_az}
machine:`hostname`
[data]
START_HEAD
}

set -o xtrace
CLOUD=""
BENCHMARK_OPTIONS=""
SERIES_NAME=""
REPORT_VERSION=""
TARGETS=""
num_job=16
size=10G
iodepth=32
run_time=300
test_name=""
io_type_list=""
rwmix_list="50"
bs_list=""
volume_type=""
volume_size=0
volume_id=""
cpu=2
men=4
os="CentOS 7.1 x86_64 (64bit)"
region_az=""
while [ $# -gt 0 ]; do
  case "$1" in
    -h| --help) usage ;;
    -c| --cloud) shift; CLOUD=$1;;
    -vt| --volume_type) shift; VOLUME_TYPE=$1;;
    -vs| --volume_size) shift; VOLUME_SIZE=$1;;
    -vi| --volume_id) shift; VOLUNE_ID="$1";;
    -cp| --cpu) shift; CPU=$1;;
    -m| --mem) shift; MEM=$1;;
    -o| --os) shift; OS=$1;;
    -r| --region) shift; REGION=$1;;
    -a| --az) shift; AZ=$1;;
    -b| --benchmarks) shift; BENCHMARK_OPTIONS=$1 ;;
    -s| --series) shift; SERIES_NAME=$1 ;;
    -t| --targets) shift; TARGETS=$1 ;;
    *) shift ;;
  esac
  shift
done

start_time=`date +%Y-%m-%d`
file_name="${CLOUD}_${TARGETS}_${start_time}"
result_name="result_${file_name}"
region_az="${REGION}_${AZ}"
add_header $VOLUME_TYPE $VOLUME_SIZE $VOLUNE_ID  $CLOUD $region_az  $start_time >> $result_name
arr=(${BENCHMARK_OPTIONS//,/ })
for i in ${arr[@]}  
do  
    case "$i" in
      iops)  io_type_list="randrw"; rwmix_list="100/0,95/5,65/35,50/50,35/65,5/95,0/100";
             bs_list="4,8,16,32,64,128,1024"; test_name="IOPS";;
      throughput) io_type_list="write"; rwmix_list="100/0,0/100";
                  bs_list="1024"; test_name="Throughut";;
      latency)  io_type_list="randrw"; iodepth=1; num_job=1;
                bs_list="4,8";rwmix_list="100/0,65/35,0/100"; test_name="latency";;
      stability)  io_type_list="randwrite"; bs_list="4"; test_name="Stability"; 
                  run_time=86400;;
      old_benchmark) io_type_list="write,randwrite,randrw,read,randread"; test_name="old_benchmark";
                     bs_list="4,8,16,32,64,128,1024"; iodepth=32; num_job=16;;
      old_latency) io_type_list="write,randwrite,randrw,read,randread"; test_name="old_latency";
                   bs_list="4"; iodepth=1; num_job=1;;
      *) ;;  
    esac 
    sh perf_tools.sh --dev_name "/dev/$TARGETS" --iodepth $iodepth --io_type $io_type_list --rwmix $rwmix_list --numjobs $num_job --bs_list $bs_list --size $size --run_time $run_time --test_name $test_name  --file_name "$file_name"&
    sleep 5
    if [[ $test_name == "Stability" ]];then
        while ((1));do
            pid=`ps -ef | grep "perf_tools.sh" | grep -v grep | awk '{print $2}'`
            if [[ $pid != "" ]];then
                collect_disk_info $TARGETS $iostat_name
                sleep 60 
            else
                break
            fi
        done
    fi    
    wait
    echo "$test_name test finish"
done  

