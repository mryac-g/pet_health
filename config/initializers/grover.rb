Rails.application.config.middleware.use Grover::Middleware

Grover.configure do |config|
  config.options = {
    format: "A4",
    print_background: true,
    margin: { top: "1cm", bottom: "1cm", left: "1cm", right: "1cm" },
    wait_until: "networkidle0",
    emulate_media: "print",
    # CI(GitHub Actions)やRenderなどのコンテナ環境ではChromeのサンドボックスを
    # 使う権限が無く、指定しないとヘッドレスChromeの起動自体が落ちる。
    # このアプリでレンダリングするのは自アプリの画面のみ(信頼できない外部HTMLは扱わない)ため無効化する
    launch_args: ["--no-sandbox", "--disable-setuid-sandbox"]
  }
end
