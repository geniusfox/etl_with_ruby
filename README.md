  依赖ActiveRecode模块的特性，尽量自动的从source数据库抽取数据，通过简单的格式或者逻辑处理，写入到target的数据库。 适合小项目的数据抽取和日报生成。推荐数据展示用metabase。

# 基本功能
* 不依赖Rails的整个框架，不用鲜用Rails生成的一堆代码，包括View和Controller
* 参考rails的rake generate/migrate 命令，自动的生成target库的表和ActiveRecode的代码
* 生成rake脚本，任务以来逻辑用rake嵌套完成
* 利用whenever生成crontab定时任务
* log4r模块记录每个etl任务的运行状体

