#!/bin/sh

#-------------------------------------------------------------------------------
#  Usage: warpper fio exec
#  Authors: ksk0014<kandkang0014@gmail.com>
#  Date: 2017.03.13
#-------------------------------------------------------------------------------
 
function usage() {
    cat << EOF
Usage: perf_tools.sh

Wrapper fio tools:
    The tool can help you to exec fio test automatically.
    Please run such as bash +x perf_tools.sh

Options:
  --help | -h
    Print usage information.
  --dev_name
    Device name
  --iodepth 
    IOdepth: 64
  --io_type 
    IOtype: read,write,rw,randread,randwrite,randrw
  --rwmix
    RWmix: 100/0,95/5,65/35,50/50,35/65,5/95,0/100
  --numjobs
    num_job: 16
  --bs_list
    bs_list: 4,8,16,32,64,1024"
  --size
    size: 10G
  --run_time
    run_time(s): 600
  --test_name
    test_name: Latency,IOPS,Throughput,Stability
  --file_name
    file_name: fio result
  --result_name
    result_name: parse result
EOF
    exit 0
}
 
function exe_fio() {
    local dev_name=$1
    local num_job=$2
    local iodepth=$3
    local io_type=$4
    local bs=$5
    local size=$6
    local rwmixwrite=$7
    local run_time=$8

    if [[ $rwmixwrite =~ NULL ]] && [[ $io_type =~ rand ]];then
        fio  -filename=${dev_name} -thread -numjobs=${num_job} -direct=1 -iodepth=${iodepth} -rw=${io_type} -ioengine=libaio -bs=${bs}k -size=${size}  -group_reporting -name=perf --output-format=json --runtime=${run_time} --norandommap --time_based
    elif [[ $io_type =~ rand ]];then 
        fio  -filename=${dev_name} -thread -numjobs=${num_job} -direct=1 -iodepth=${iodepth} -rw=${io_type} -ioengine=libaio -bs=${bs}k -size=${size} -rwmixwrite=${rwmixwrite} -group_reporting -name=perf --output-format=json --runtime=${run_time} --norandommap --time_based
    elif [[ $rwmixwrite =~ NULL ]];then
        fio  -filename=${dev_name} -thread -numjobs=${num_job} -direct=1 -iodepth=${iodepth} -rw=${io_type} -ioengine=libaio -bs=${bs}k -size=${size} -group_reporting -name=perf --output-format=json --runtime=${run_time} --randrepeat=0 --time_based
    else
        fio  -filename=${dev_name} -thread -numjobs=${num_job} -direct=1 -iodepth=${iodepth} -rw=${io_type} -ioengine=libaio -bs=${bs}k -size=${size} -rwmixwrite=${rwmixwrite} -group_reporting -name=perf --output-format=json --runtime=${run_time} --randrepeat=0 --time_based
    fi 
}

function parse_fio() {  
    output=$1
    rclat99=$(python -c "import json; dict_ret=json.loads('''$output'''); print dict_ret['jobs'][0]['read']['clat']['percentile']['99.00'];")
    wclat99=$(python -c "import json; dict_ret=json.loads('''$output'''); print dict_ret['jobs'][0]['write']['clat']['percentile']['99.00'];")
    rclat999=$(python -c "import json; dict_ret=json.loads('''$output'''); print dict_ret['jobs'][0]['read']['clat']['percentile']['99.90'];")
    wclat999=$(python -c "import json; dict_ret=json.loads('''$output'''); print dict_ret['jobs'][0]['write']['clat']['percentile']['99.90'];")
    rclat9999=$(python -c "import json; dict_ret=json.loads('''$output'''); print dict_ret['jobs'][0]['read']['clat']['percentile']['99.99'];")
    wclat9999=$(python -c "import json; dict_ret=json.loads('''$output'''); print dict_ret['jobs'][0]['write']['clat']['percentile']['99.99'];")

    wclatmin=$(python -c "import json; dict_ret=json.loads('''$output'''); print dict_ret['jobs'][0]['write']['clat']['min'];")
    wclatmax=$(python -c "import json; dict_ret=json.loads('''$output'''); print dict_ret['jobs'][0]['write']['clat']['max'];")
    wclatmean=$(python -c "import json; dict_ret=json.loads('''$output'''); print dict_ret['jobs'][0]['write']['clat']['mean'];")
    wclatstddev=$(python -c "import json; dict_ret=json.loads('''$output'''); print dict_ret['jobs'][0]['write']['clat']['stddev'];")

    rclatmin=$(python -c "import json; dict_ret=json.loads('''$output'''); print dict_ret['jobs'][0]['read']['clat']['min'];")
    rclatmax=$(python -c "import json; dict_ret=json.loads('''$output'''); print dict_ret['jobs'][0]['read']['clat']['max'];")
    rclatmean=$(python -c "import json; dict_ret=json.loads('''$output'''); print dict_ret['jobs'][0]['read']['clat']['mean'];")
    rclatstddev=$(python -c "import json; dict_ret=json.loads('''$output'''); print dict_ret['jobs'][0]['read']['clat']['stddev'];")

    read_iops=$(python -c "import json; dict_ret=json.loads('''$output'''); print dict_ret['jobs'][0]['read']['iops'];")
    write_iops=$(python -c "import json; dict_ret=json.loads('''$output'''); print dict_ret['jobs'][0]['write']['iops'];")
    read_bw=$(python -c "import json; dict_ret=json.loads('''$output'''); print dict_ret['jobs'][0]['read']['bw'];")
    write_bw=$(python -c "import json; dict_ret=json.loads('''$output'''); print dict_ret['jobs'][0]['write']['bw'];") 
    
    test_name=$2
    bs=$3
    io_type=$4
    rwmixwrite=$5
    exec_time=$6
    if [ ${test_name} == "old_benchmark" ] || [ ${test_name} == "old_latency" ];then
        if [ ${io_type} == randrw ];then
            name="randrw"  
            rwmixwrite=50
        elif [ ${io_type} == randread ];then
            name="random_read"
        elif [ ${io_type} == randwrite ];then
            name="random_write"
        elif [ ${io_type} == read ];then
            name="sequential_read"
        elif [ ${io_type} == write ];then
            name="sequential_write"
        fi
        if [ ${test_name} == "old_latency" ];then
            name="${name}_1job"
        fi
    else
        ((rwmixread=100 - $rwmixwrite))
        if [[ ${io_type} =~ rand* ]];then
            name="rand_r${rwmixread}_w${rwmixwrite}"
        else
            name="sequential_r${rwmixread}_w${rwmixwrite}"
        fi
    fi
    if [ ${rwmixwrite} == "0" ] || [ ${rwmixwrite} == "100" ] || [ ${rwmixwrite} == "NULL" ];then
        iops=$(echo "$read_iops+$write_iops" | bc)
        echo "iops ${bs}KB ${test_name} ${name} ${exec_time} ${iops}"
        bw=$(echo "$read_bw+$write_bw" | bc)
        echo "throughput ${bs}KB ${test_name} ${name} ${exec_time} ${bw}"
        clat99=$(echo "$rclat99+$wclat99" | bc)
        echo "latency_99 ${bs}KB ${test_name} ${name} ${exec_time} ${clat99}"
        clat999=$(echo "$rclat999 + $wclat999" |bc)
        echo "latency_99_9 ${bs}KB ${test_name} ${name} ${exec_time} ${clat999}"
        clat9999=$(echo "$rclat9999+$wclat9999" | bc)
        echo "latency_99_99 ${bs}KB ${test_name} ${name} ${exec_time} ${clat9999}"
        clatmax=$(echo "$rclatmax+$wclatmax" | bc)
        echo "latency_max ${bs}KB ${test_name} ${name} ${exec_time} ${clatmax}"
        clatmean=$(echo "$rclatmean+$wclatmean" | bc)
        echo "latency_avg ${bs}KB ${test_name} ${name} ${exec_time} ${clatmean}"
        clatstddev=$(echo "$rclatstddev+$wclatstddev" | bc)
        echo "latency_wave ${bs}KB ${test_name} ${name} ${exec_time} ${clatstddev}"
    else
        echo "iops ${bs}KB ${test_name} ${name} ${exec_time} ${read_iops}"
        echo "throughput ${bs}KB ${test_name} ${name}  ${exec_time} ${read_bw}"
        echo "latency_99 ${bs}KB ${test_name} ${name} ${exec_time} ${rclat99}"
        echo "latency_99_9 ${bs}KB ${test_name} ${name} ${exec_time} ${rclat999}"
        echo "latency_99_99 ${bs}KB ${test_name} ${name} ${exec_time} ${rclat9999}"
        echo "latency_max ${bs}KB ${test_name} ${name} ${exec_time} ${rclatmax}" 
        echo "latency_avg ${bs}KB ${test_name} ${name} ${exec_time} ${rclatmean}"
        echo "latency_wave ${bs}KB ${test_name} ${name} ${exec_time} ${rclatstddev}"        
        //
        echo "iops ${bs}KB ${test_name} ${name} ${exec_time} ${wirte_iops}"
        echo "throughput ${bs}KB ${test_name} ${name}  ${exec_time} ${wirte_bw}"
        echo "latency_99 ${bs}KB ${test_name} ${name} ${exec_time} ${wclat99}"
        echo "latency_99_9 ${bs}KB ${test_name} ${name} ${exec_time} ${wclat999}"
        echo "latency_99_99 ${bs}KB ${test_name} ${name} ${exec_time} ${wclat9999}"
        echo "latency_max ${bs}KB ${test_name} ${name} ${exec_time} ${wclatmax}" 
        echo "latency_avg ${bs}KB ${test_name} ${name} ${exec_time} ${wclatmean}"
        echo "latency_wave ${bs}KB ${test_name} ${name} ${exec_time} ${wclatstddev}"
    fi
}

set -o xtrace

dev_name=""
iodepth=32
io_type_list=""
rwmix_list=""
num_job=16
bs_list=""
size="10G"
run_time=600
test_name=""
file_name=""

while [ $# -gt 0 ]; do
  case "$1" in
    -h| --help) usage ;;
    --dev_name) shift; dev_name=$1;;
    --iodepth) shift; iodepth=$1;;
    --io_type) shift; io_type_list=$1;;
    --rwmix) shift; rwmix_list=$1;;
    --numjobs) shift; num_job=$1;;
    --bs_list) shift; bs_list=$1;;
    --size) shift; size=$1;;
    --run_time) shift; run_time=$1;;
    --test_name) shift; test_name=$1;;
    --file_name) shift; file_name=$1;;
    *) shift ;;
  esac
  shift
done

result_name="result_${file_name}"

OLD_IFS="$IFS" 
IFS="," 
bs_list=(${bs_list})
io_type_list=(${io_type_list})
rwmix_list=(${rwmix_list})
IFS="$OLD_IFS" 

for bs in ${bs_list[@]} 
do
    for io_type in ${io_type_list[@]}
    do
        if [[ $io_type =~ rw ]] && [[ "$test_name" != "old_benchmark" ]];then
            for rwmix in ${rwmix_list[@]}
            do 
                rwmixread=$(echo $rwmix| cut -d"/" -f1)
                rwmixwrite=$(echo $rwmix| cut -d"/" -f2)
                echo "${test_name}_${bs}KB_${io_type}_r${rwmixread}_w${rwmixwrite}" >> $file_name 
                exec_time=`date +%Y-%m-%d\ %H:%M:%S`
                output=$(exe_fio "${dev_name}" "${num_job}" "${iodepth}" "${io_type}" "${bs}" "${size}" "${rwmixwrite}" "${run_time}") 
                echo $output >> $file_name
                parse_fio "$output" $test_name $bs $io_type $rwmixwrite "$exec_time" >> $result_name
            done
        else
            echo "${test_name}_${bs}KB_${io_type}" >> $file_name
            exec_time=`date +%Y-%m-%d\ %H:%M:%S`
            output=$(exe_fio "${dev_name}" "${num_job}" "${iodepth}" "${io_type}" "${bs}" "${size}" "NULL" "${run_time}") 
            echo $output >> $file_name
            if [[ $test_name == "old_benchmark" ]] || [[ $test_name == "old_latency" ]];then
                parse_fio "$output" $test_name $bs $io_type "NULL" "$exec_time" >> $result_name
            fi
        fi
    done
done


