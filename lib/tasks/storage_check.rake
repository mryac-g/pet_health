namespace :storage do
  desc "Supabase Storageへの接続確認"
  task check: :environment do
    SupabaseStorage.client.head_bucket(bucket: SupabaseStorage.bucket)
    puts "bucket:  #{SupabaseStorage.bucket}"
    puts "接続確認OK"
  rescue => e
    puts "接続確認NG: #{e.class}: #{e.message}"
  end
end
