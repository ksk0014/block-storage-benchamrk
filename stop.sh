#!/bin/sh

#-------------------------------------------------------------------------------
#  Usage: perf stop scripts
#  Authors: ksk0014<kandkang0014@gmail.com>
#  Date: 2017.03.13
#-------------------------------------------------------------------------------

ps -ef | grep run_benchmark |grep -v grep |awk '{print $2}' | xargs kill
ps -ef | grep perf_tools |grep -v grep |awk '{print $2}' | xargs kill
ps -ef | grep fio |grep -v grep |awk '{print $2}' | xargs kill



