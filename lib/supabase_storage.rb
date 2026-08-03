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

  # Supabaseの公開URL形式: https://<project-ref>.supabase.co/storage/v1/object/public
  def self.public_url(key)
    "#{ENV.fetch('SUPABASE_STORAGE_PUBLIC_URL_BASE')}/#{bucket}/#{key}"
  end

  def self.key_from_public_url(url)
    prefix = "#{ENV.fetch('SUPABASE_STORAGE_PUBLIC_URL_BASE')}/#{bucket}/"
    url.delete_prefix(prefix)
  end
end
