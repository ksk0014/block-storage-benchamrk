# block storage perf benchmark tool #

支持对块设备按照SNIA PTS测试标准进行性能基准测试
目前支持四种基准场景：

* IOPS测试：侧重小写随机性能
* 吞吐测试: 侧重大写顺序性能
* 延迟测试: 侧重单线程读写延迟性能
* 稳定性测试：侧重长时间随机读写稳定性波动性能

工具在云环境块存储产品客户维度提供了一种基于模板的简洁明了的性能基准测试方案

测试工具: fio

测试结果 : 以result_开头的文件中记录具体IO场景下的性能指标数据

运行方式 : 参见sh run.sh help 

