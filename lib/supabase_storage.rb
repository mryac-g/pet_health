require "aws-sdk-s3"

# Supabase Storage(S3互換API)へのアップロード用クライアント。
# 認証情報はSupabaseダッシュボードのProject Settings > Storage > S3 Connectionから取得する。
module SupabaseStorage
  def self.client
    @client ||= Aws::S3::Client.new(
      access_key_id: ENV.fetch("SUPABASE_S3_ACCESS_KEY_ID"),
      secret_access_key: ENV.fetch("SUPABASE_S3_SECRET_ACCESS_KEY"),
      region: ENV.fetch("SUPABASE_S3_REGION"),
      endpoint: ENV.fetch("SUPABASE_S3_ENDPOINT"),
      force_path_style: true
    )
  end

  def self.bucket
    ENV.fetch("SUPABASE_S3_BUCKET")
  end
end
