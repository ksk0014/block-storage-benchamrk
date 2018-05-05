#!/bin/sh

#-------------------------------------------------------------------------------
#  Usage: common function set
#  Authors: ksk0014<kandkang0014@gmail.com>
#  Date: 2017.03.13
#-------------------------------------------------------------------------------

function collect_disk_info() {
    dev_name=$1
    file_name=$2
    exec_time=`date +%Y-%m-%d\ %H:%M:%S`
    disk_info=`iostat -d -x -k 1 10 | grep $dev_name`
    OLD_IFS="$IFS" 
    IFS="vdf" 
    disk_info_list=(${disk_info})
    IFS="$OLD_IFS" 
    avg_r_s=0.00
    avg_w_s=0.00
    avg_rkB_s=0.00
    avg_wkB_s=0.00
    avg_avgqu_sz=0.00
    avg_await=0.00
    avg_svctm=0.00
    avg_util=0.00
    count=0
    for s in "${disk_info_list[@]}"
    do
        if [[ $s == '' ]] || [ $count -le 2 ];then
            ((count++))
            continue
        fi
        ((count++))
        r_s=`echo ${s}| awk -F' ' '{print $4}'` 
        w_s=`echo ${s}| awk -F' ' '{print $5}'`
        rkB_s=`echo ${s}| awk -F' ' '{print $6}'`
        wkB_s=`echo ${s}| awk -F' ' '{print $7}'`
        avgqu_sz=`echo ${s}| awk -F' ' '{print $9}'`
        await=`echo ${s}| awk -F' ' '{print $10}'`
        svctm=`echo ${s}| awk -F' ' '{print $13}'`
        util=`echo ${s}| awk -F' ' '{print $14}'`
        echo $avg_r_s
        avg_r_s=$(echo "$avg_r_s+$r_s" | bc)
        avg_w_s=$(echo "$avg_w_s+$w_s"|bc)
        avg_rkB_s=$(echo "$avg_rkB_s+$rkB_s" | bc)
        avg_wkB_s=$(echo "$avg_wkB_s+$wkB_s" | bc)
        avg_avgqu_sz=$(echo "$avg_avgqu_sz+$avgqu_sz" | bc)
        avg_await=$(echo "$avg_await+$await" | bc)
        avg_svctm=$(echo "$avg_svctm+$svctm" | bc)
        avg_util=$(echo "$avg_util+$util" | bc)
    done
    avg_r_s=$(scale=2;echo "$avg_r_s/9" | bc)
    avg_w_s=$(scale=2;echo "$avg_w_s/9"|bc)
    avg_rkB_s=$(scale=2;echo "$avg_rkB_s/9" | bc)
    avg_wkB_s=$(scale=2;echo "$avg_wkB_s/9" | bc)
    avg_avgqu_sz=$(scale=2;echo "$avg_avgqu_sz/9" | bc)
    avg_await=$(scale=2;echo "$avg_await/9" | bc)
    avg_svctm=$(scale=2;echo "$avg_svctm/9" | bc)
    avg_util=$(scale=2;echo "$avg_util/9" | bc) 
    echo "Stability r_s ${exec_time} ${avg_r_s}" >> $file_name
    echo "Stability w_s ${exec_time} ${avg_w_s}" >> $file_name
    echo "Stability rkB_s ${exec_time} ${avg_rkB_s}" >> $file_name
    echo "Stability wkB_s ${exec_time} ${avg_wkB_s}" >> $file_name
    echo "Stability avgqu_sz ${exec_time} ${avg_avgqu_sz}" >> $file_name
    echo "Stability await ${exec_time} ${avg_await}" >> $file_name
    echo "Stability svctm ${exec_time} ${avg_svctm}" >> $file_name
    echo "Stability util ${exec_time} ${avg_util}" >> $file_name
}

