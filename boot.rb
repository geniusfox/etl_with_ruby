#environment.rb
require 'bundler/setup'
require 'active_record'
require 'yaml'
require 'logger'


###建立source目标数据库的连接，承担在source库执行SQL的任务
class EtlData < ActiveRecord::Base
  self.table_name = 'users'
  establish_connection(YAML::load(File.open('database.yml'))['source'])
end


module EtlPipline
  extend ActiveSupport::Concern
  attr_accessor :seg_name

  # module ClassMethods
  #   def seg_column_name_as(new_name=nil)
  #     self.seg_name = new_name.to_sym unless new_name.nil?
  #   end
  #
  # end

  included do
    class_attribute:seg_name, instance_accessor: false, default: "seg_date"
  end

=begin
所有Etl任务的模版，默认的数据库操作目标是dest库,基本结构支持
* 指定seg_tag标签，默认以天为单位切割数据
* 按照seg_tag清除数据后，按照默认条件抽取数据后直接插入
=end
# class EtlPipline < ActiveRecord::Base

  # after_initialize @seg_tag='seg_tag'

  ActiveRecord::Base.logger= Logger.new(STDOUT)
  ActiveRecord::Base.logger.level = Logger::INFO if ENV["debug"].nil?

  # Seg_name = 'seg_name'
  # self.seg_name = 'seg_tag'

  # def seg_name=(new_seg=nil)
  #   self.seg_name= new_seg
  # end

  #通过SQL直接从source数据源抽取数据
  def extract(find_sql)
    # trans = EtlData.find_by_sql(find_sql)
    trans = EtlData.connection.select_all(find_sql)
    logger.debug("Source: #{find_sql}")
    logger.info("Source: mathced records:#{trans.length}")
    trans.each do |item|
      yield(item)
    end
  end

  #根据数据表的分割标志，构造抽取的SQL串,每个pipline必须实现的方法
  def build_sql_with_seg(seg_data)
    raise('You must implement sql!')
  end

  #单行数据的转化，如lastname和first_name字段合成user_name
  def transform(source_row)
  end


  #根据指定的切割日期或者其他条件运行etl，如抽取指定日期的订单导入数据仓库
  def etl_pipline(seg_data)
    logger.info("##################################################################")
    logger.info("")
    seg_column_name = self.class.seg_name
    delete_rows = self.class.where(seg_column_name.to_sym =>seg_data).delete_all
    logger.info("Clean: #{delete_rows} with #{seg_data}")
    sucess,failed = 0,0
    col_keys = self.class.column_names.select{|k| !['id',seg_column_name].include? k }
    extract(build_sql_with_seg(seg_data)){|item|
      dest = self.class.new
      begin
        transform(item) #字段变换
        col_keys.each{|att_name|
          dest.send("#{att_name}=", item[att_name]) if item.has_key? att_name
        }
        # dest.seg_name = seg_data #统一设置切分数据段的标志
        dest.send("#{seg_column_name}=", seg_data) #统一设置切分数据段的标志
        dest.save!
      rescue Exception => e
        failed +=1
        logger.error(e.message)
      end
      sucess+=1
    }
    logger.info("Write:success:#{sucess}, failed:#{failed}")
    logger.info("")
    logger.info("##################################################################")
  end

end



#建立数据库链接
class Connection
  def self.connection_details
    #默认的数据库连接
    return dbconfig = YAML::load(File.open('database.yml'))['dest']
  end

  def self.connect(options={})
    # if options[:admin]
    #   ActiveRecord::Base.establish_connection(admin_connection_details)
    # else
    ActiveRecord::Base.establish_connection(connection_details)
    # end
  end
end
# require all the models
#Dir.glob("models/*") { |file| require file }
# open a connection to the db
Connection.connect

#加载modle目录下的所有ruby文件
# recursively requires all files in app/model/*.rb and down that end in .rb
Dir.glob('./app/model/*.rb') do |active_recode_file|
  # puts "loading file #{active_recode_file}"
  require active_recode_file
end
