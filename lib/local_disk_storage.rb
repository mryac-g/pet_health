# SupabaseのS3認証情報が無いローカル開発環境向けの代替ストレージ。
# public/uploads 配下に保存し、Railsの静的ファイル配信でそのまま公開URLとして返す。
module LocalDiskStorage
  ROOT = Rails.root.join("public/uploads")

  def self.upload(key:, file:)
    path = ROOT.join(key)
    FileUtils.mkdir_p(path.dirname)
    File.binwrite(path, file.read)
  end

  def self.delete(key:)
    FileUtils.rm_f(ROOT.join(key))
  end

  def self.presigned_url(key, expires_in: nil)
    "/uploads/#{key}"
  end
end
