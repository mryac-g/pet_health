Rails.application.config.middleware.use Grover::Middleware

Grover.configure do |config|
  config.options = {
    format: "A4",
    print_background: true,
    margin: { top: "1cm", bottom: "1cm", left: "1cm", right: "1cm" },
    wait_until: "networkidle0",
    emulate_media: "print"
  }
end
