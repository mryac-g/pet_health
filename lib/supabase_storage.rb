require "aws-sdk-s3"

# Supabase Storage(S3互換API)へのアップロード用クライアント。
# 認証情報はSupabaseダッシュボードのProject Settings > Storage > S3 Connectionから取得する。
#
# 本番以外(ローカル開発など)ではS3認証情報を用意しなくても試せるよう、
# LocalDiskStorage(public/uploads配下への保存)に自動で委譲する。
module SupabaseStorage
  def self.use_local_disk?
    !Rails.env.production?
  end

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

  def self.upload(key:, file:)
    return LocalDiskStorage.upload(key: key, file: file) if use_local_disk?

    client.put_object(bucket: bucket, key: key, body: file.read, content_type: file.content_type)
  end

  def self.delete(key:)
    return LocalDiskStorage.delete(key: key) if use_local_disk?

    client.delete_object(bucket: bucket, key: key)
  end

  # 非公開バケットのため、一時的にのみ有効な署名付きURLをその都度発行する
  def self.presigned_url(key, expires_in: 5.minutes)
    return LocalDiskStorage.presigned_url(key) if use_local_disk?

    Aws::S3::Presigner.new(client: client).presigned_url(:get_object, bucket: bucket, key: key, expires_in: expires_in.to_i)
  end
end
