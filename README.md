# 基本介绍
  ETL的基本功能包括：”extract, transform, load“ 三个部分。如现在很多分析工作基本是遵循从在线产品库定期的读取数据；然后按照分析的目标清洗数据（比如：做格式变化或者订单成交价格计算等）；最后写入到数据报表系统能读取目标数据库。
  
* 系统依赖ActiveRecode模块的特性，按照生成的modle对象插入目标数据，以期望减少重复代码；
* 利用generate&migrate的方式，生成报表数据库
* 因为源数据结构和业务逻辑问题，采用拼接SQL的方式提取数据
* 数据清洗和字段变换代码逻辑需要手工完成
* 默认报表数据库表用seg_name切割（比如按天抽取交易订单），每次pinline运行都会将该批次数据插入统一的seg_name.之后再次运行相同seg_name值的任务，则会被delete后再次插入。

# 开始使用
## 基本配置
* 编辑database.yml文件，配置dest写入的目标数据库和抽取数据的source库
* 检查app/model 和db/migrate 目录是否存在

## 样例代码
* <p>参考rails，生成migrate的db对象:/db/migrate/20211027165917_create_sample_users.rb </p>
<code>
    rake db:generate create_sample_users
</code>

* 打开db/migrate目录文件，按照migrate规范编辑<code>self.up()</code>方法，代码如下：
```ruby
    create_table :sample_users do |t|
      t.string :user_name, :limit=>20
      t.decimal :order_amount, :precision=>7, :scale =>2, :default => 0
      t.string :buy_date, :limit=>10
      t.string :seg_name
    end
``` 

* 然后执行<code>rake db:migrate </code>创建数据库表
* 执行<code>rake db:generate_model sample_user</code>
* 编辑app/model/sampel_user.rb。按照ETL框架要求，必须实现<code>def build_sql_with_seg(seg_data)</code>方法。<code>def transform(row)</code>方法如果没有被实现，怎默认按照SQL提取的字段列表和目标数据库表字段的交集插入

```ruby
     #根据切割数据的时间戳，从课时系统抽取用户课程记录
     #切记SQL的字段名要和目标数据表的列名保持一致，否则无法自动提取
     def build_sql_with_seg(seg_data)
          find_sql="select b.name as first_name, price order_amount, course_count as buy_hours "
          find_sql+="from member_courses as a, members as b where a.member_id = b.id and "
          find_sql+="left(buy_time,4) =left('#{seg_data}',4)"
          find_sql
     end

     #可以增加或者修改字段，如在user_name字段增加后缀/te
        def transform(row)
          row["user_name"] = "#{row['first_name']}/te"
        end
```

* 最后测试：<code>rake etl:run_etl_pipline \[SampleUser\] </code>



