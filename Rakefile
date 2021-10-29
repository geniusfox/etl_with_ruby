require "active_record"
require File.expand_path('../boot',__FILE__)

namespace :db do

  # desc "Create the database"
  # task :create do
  #   #ActiveRecord::Base.establish_connection(db_config_admin)
  #   ActiveRecord::Base.connection.create_database(db_config["database"])
  #   puts "Database created."
  # end

  task :environment do
    # Take in specified database as an argument
    # DB = ENV['db']
    MIGRATIONS_DIR = 'db/migrate/'
    MODEL_DIR = 'app/model/'
  end

  # desc 'Init, checking directory and config files'
  # task :init=> :environment do 
  #   # puts Dir.exist? MIGRATIONS_DIR    
  #   MIGRATIONS_DIR.split('/').each {|d| 
  #     Dir.mkdir(d) unless Dir.exist? d
  #     Dir.chdir(d)
  #   }
  # end

  desc "Migrate the database"
  task :migrate => :environment do
    ActiveRecord::Migration.verbose = true
    migrations = if ActiveRecord.version.version >= '5.2'
      ActiveRecord::Migration.new.migration_context.migrations
    else
      ActiveRecord::Migrator.migrations('db/migrate')
    end
    ActiveRecord::Migrator.new(:up, migrations, nil).migrate
    puts "Database migrated."
  end
  

  desc "RollBack database"
  task :rollback => :environment do
    ActiveRecord::Migration.verbose = true
  end

  desc "Generate db/migrate and active_modle file."
  task :generate do
    name = ARGV[1] || raise("Specify name: rake g:migration your_migration")
    timestamp = Time.now.strftime("%Y%m%d%H%M%S")
    path = File.expand_path("../db/migrate/#{timestamp}_#{name}.rb", __FILE__)
    migration_class = name.split("_").map(&:capitalize).join

    File.open(path, 'w') do |file|
      file.write <<-EOF
class #{migration_class} < ActiveRecord::Migration[4.2]
  
  def self.up
  end

  def self.down
  end
end
      EOF
    end
    puts "Migration #{path} created"
    abort # needed stop other tasks
  end

  desc 'Generte app/model '
  task :generate_model do
    name = ARGV[1] || raise("Specify name: rake g:migration your_migration")
    path = File.expand_path("../app/model/#{name}.rb", __FILE__)

    activerecode_class = name.split("_").map(&:capitalize).join

    File.open(path, 'w') do |file|
      file.write <<-EOF
#!/bin/ruby

class #{activerecode_class} < ActiveRecord::Base
  include EtlPipline

  def build_sql_with_seg(seg_data)
    raise('You must implement sql!')
  end

  def transform(row)
  end
end
      EOF
    end
    puts "Activerecode  #{path} created"
    abort # needed stop other tasks
  end

  # desc "Reset the database"
  # task :reset => [:drop, :create, :migrate]

  # desc 'Create a db/schema.rb file that is portable against any DB supported by AR'
  # task :schema do
  #   # ActiveRecord::Base.establish_connection(db_config)
  #   require 'active_record/schema_dumper'
  #   filename = "db/schema.rb"
  #   File.open(filename, "w:utf-8") do |file|
  #     ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, file)
  #   end
  # end
end


namespace :etl do
  desc '默认运行指定ActiveRecode对象的etl_pipline'
  #rake etl:run_etl_pipline\[SampleUser\]
  task :run_etl_pipline, [:model_name] do |t, args|
    # puts "loading :#{args.model_name}"
    obj = Object.const_get(args.model_name)
    obj.new.etl_pipline Time.new.strftime("%Y-%m-%d")
  end
end
