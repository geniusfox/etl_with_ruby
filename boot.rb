#environment.rb
require 'bundler/setup'
require 'active_record'
require 'yaml'
require 'logger'


###建立source目标数据库的连接，承担在source库执行SQL的任务 ###
class EtlData < ActiveRecord::Base
  self.table_name = 'users'
  establish_connection(YAML::load(File.open('database.yml'))['source'])
end


### 所有Etl任务的模版，默认的数据库操作目标是dest库 ###
class EtlMaker < ActiveRecord::Base
  ActiveRecord::Base.logger= Logger.new(STDOUT)
  ActiveRecord::Base.logger.level = Logger::INFO if ENV["debug"].nil?
  # ActiveRecord::Base.logger.level = Logger::DEBUG unless ENV["debug"].nil?

  def self.primary_key=(key)
    @primary_key = key
  end

  def self.set_atts(pk, kws={})
    item = self.where(@primary_key=>pk)
    if(item.size ==1)
      self.update_atts(pk, kws, item)
    else
     item = create({@primary_key => pk}.merge(kws))
    end
  end


  def self.update_atts(pk, kws ={}, find_item =nil)
    item = find_item|| self.where(@primary_key=>pk)
    if(item.size ==1)
      item.first.attributes = kws
      item.first.save
    end
  end

  #通过SQL直接从source数据源抽取数据
  def etl(find_sql)
    trans = EtlData.find_by_sql(find_sql)
    logger.debug(find_sql)
    trans.each do |item|
      yield(item)
    end
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
# recursively requires all files in ./lib and down that end in .rb
# Dir.glob('./lib/*').each do |folder|
#   Dir.glob(folder +"/*.rb").each do |file|
#     require file
#   end
# end