#!/usr/bin/env bash
set -o errexit

bundle install
npm install

# GroverがPDF生成に使うPuppeteer(ヘッドレスChrome)は、npm installの後処理で
# Chromiumを自動ダウンロードするが、既定の保存先($HOME/.cache/puppeteer)は
# Renderのビルド時とアプリ起動時で$HOMEが異なるため、せっかく落としたChromeが
# 起動時には見つからず"Could not find Chrome"エラーになる。保存先を固定パスに
# して、Renderの環境変数PUPPETEER_CACHE_DIRにも同じ値を設定しておくことで
# ビルド時・起動時の両方が同じ場所を見るようにする。
# (参考: https://render.com — PUPPETEER_CACHE_DIRをRenderダッシュボードの
#  Environmentにも設定すること)
npx puppeteer browsers install chrome

bundle exec rails assets:precompile
bundle exec rails assets:clean
bundle exec rails db:migrate
