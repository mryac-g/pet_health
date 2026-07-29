namespace :db do
  desc "現在の接続先データベース情報を表示して接続確認する"
  task check: :environment do
    config = ActiveRecord::Base.connection_db_config.configuration_hash
    ActiveRecord::Base.connection.execute("SELECT 1")

    puts "RAILS_ENV: #{Rails.env}"
    puts "host:      #{config[:host]}"
    puts "database:  #{config[:database]}"
    puts "username:  #{config[:username]}"
    puts "接続確認OK"
  end
end
