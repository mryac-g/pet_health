require Rails.root.join("lib/middleware/unauthorized_request_logger")

# DeviseのauthenticateUser!はWarden::Managerのcatch(:warden)ブロック内でthrowされ、
# その中(=より内側)にミドルウェアを追加してもthrowで素通りされてしまうため、
# Warden::Managerより外側に挿入する
Rails.application.config.middleware.insert_before Warden::Manager, Middleware::UnauthorizedRequestLogger
