# Put new schemas in this array AND database.yml search_path or db:schema:dump won't work
SOCK_SCHEMAS = [
  "org_data",
]

db_config = Rails.configuration.database_configuration[Rails.env]

SOCK_DB = db_config["database"]
SOCK_DB_USER = db_config["username"]
SOCK_DB_HOST = db_config["host"]

verbose = ENV["VERBOSE_SOCK_DB"]

require "open3"

namespace :sock do
  namespace :db do
    desc "create sock supporting tables"
    task init: [:environment] do
      print "sock:db:refresh [#{Rails.env}] ... "

      SOCK_SCHEMAS.each do |schema|
        `psql -U #{SOCK_DB_USER} -h #{SOCK_DB_HOST} -d #{SOCK_DB} -c 'create schema if not exists #{schema}'`
      end

      dir = "#{Rails.root}/db/ddl"
      stdout, stderr, _ = Open3.capture3("psql -U #{SOCK_DB_USER} -h #{SOCK_DB_HOST} -d #{SOCK_DB} -a -f #{dir}/extensions.sql")
      if stderr.include?("ERROR")
        fail("extensions.sql: #{stderr} #{stdout}")
      end

      stdout, stderr, _ = Open3.capture3("psql -U #{SOCK_DB_USER} -h #{SOCK_DB_HOST} -d #{SOCK_DB} -a -f #{dir}/users.sql")
      # if stderr.include?("ERROR")
      #   fail("extensions.sql: #{stderr} #{stdout}")
      # end

      SOCK_SCHEMAS.each do |schema|
        sql_tables = Dir["#{dir}/#{schema}/[0-9]*"].sort
        sql_functions = Dir["#{dir}/#{schema}/functions/*"].sort

        (sql_functions + sql_tables).map do |file|
          sql = File.readlines(file).join

          stdout, stderr, _ = Open3.capture3("psql -U #{SOCK_DB_USER} -h #{SOCK_DB_HOST}  #{SOCK_DB} ", stdin_data: sql)

          if stderr.include?("ERROR")
            fail("#{file}: #{stderr} #{stdout}")
          elsif verbose
            puts "#{file}: #{stdout}"
          end
        end
      end
    end

    desc "drop sock supporting tables"
    task purge: :environment do
      SOCK_SCHEMAS.each do |schema|
        stdout, stderr, _ = Open3.capture3("psql -U #{SOCK_DB_USER} -h #{SOCK_DB_HOST} -d #{SOCK_DB} -c 'drop schema if exists #{schema} cascade'")
        if stderr.include?("ERROR")
          fail("Failed to drop schema '#{schema}': #{stderr} #{stdout}")
        elsif verbose
          puts "#{schema}: #{stdout}"
        end
      end
    end

    desc "db dump"
    task dump: :environment do
      Rake::Task["db:schema:dump"].invoke
    end

    desc "load fixtures"
    task fixtures: :environment do
      Rake::Task["db:fixtures:load"].invoke
    end

    desc "refresh db [purge, init]"
    task refresh: [:purge, :init] do
      Rake::Task["db:schema:dump"].invoke

      file = "#{Rails.root}/db/structure.sql"
      data = File.read(file)
      File.open(file, "w") do |fd|
        fd.puts("CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\" with schema public;")
        fd.puts("CREATE EXTENSION IF NOT EXISTS \"ltree\" with schema public;")
        fd.puts("CREATE EXTENSION IF NOT EXISTS \"pg_trgm\" with schema public;")
        fd.puts(data)
      end

      Rake::Task["db:fixtures:load"].invoke

      puts "done"
    end
  end
end
