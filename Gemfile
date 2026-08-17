source "https://rubygems.org"

ruby "3.3.6"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 7.1.6"

# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem "sprockets-rails"

# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"

# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"

# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"

# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"

# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"

# Use Tailwind CSS [https://github.com/rails/tailwindcss-rails]
gem "tailwindcss-rails"

# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# Use Redis adapter to run Action Cable in production
# gem "redis", ">= 4.0.1"

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
gem "bcrypt", "~> 3.1.7"

# Flexible authentication solution for Rails [https://github.com/heartcombo/devise]
gem "devise"

# Locale data for Rails i18n (validation messages, date/time formats, etc.) [https://github.com/svenfuchs/rails-i18n]
gem "rails-i18n"

# Deviseのメッセージ(ログイン/ログアウト等)の日本語ロケール [https://github.com/tigrish/devise-i18n]
gem "devise-i18n"

# S3クライアント。Active StorageからSupabase Storage(S3互換)に接続するために使用
gem "aws-sdk-s3", require: false

# サマリー画面をPDF化するため、ヘッドレスChrome(Puppeteer)経由でHTMLをPDFに変換する
gem "grover"

# Brevo APIでメール送信するためのActionMailerアダプター。
# Renderの無料プランはSMTPポート(25/465/587)への外向き通信をブロックしているため、
# SMTPではなくHTTPS経由のAPI方式でメールを送信する
gem "brevo-rails"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ]

  # Loads .env into ENV for local development/test [https://github.com/bkeepers/dotenv]
  gem "dotenv-rails"

  # Detect N+1 queries and unused eager loading [https://github.com/flyerhzm/bullet]
  gem "bullet"
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  # Add speed badges [https://github.com/MiniProfiler/rack-mini-profiler]
  # gem "rack-mini-profiler"

  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"

  # Test coverage measurement [https://github.com/simplecov-ruby/simplecov]
  gem "simplecov", require: false

  # minitest 6 breaks Rails 7.1's test runner integration; pin to the 5.x line
  gem "minitest", "~> 5.25"
end
