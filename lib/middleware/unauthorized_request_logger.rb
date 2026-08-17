module Middleware
  # 調査用ミドルウェア。/pets/newへの継続的な未認証アクセスの正体を調べるため、
  # 401を返したリクエストのUser-Agent・Referer・アクセス元IPをログに記録する。
  # DeviseのauthenticateUser!はWardenのthrow(:warden)でコントローラのafter_action
  # まで到達せずに401を返すため、Wardenより外側のRackミドルウェアとして実装する。
  # 原因特定後は削除する想定
  class UnauthorizedRequestLogger
    def initialize(app)
      @app = app
    end

    def call(env)
      # WardenはFailureApp呼び出し前にenv["PATH_INFO"]を書き換えるため、
      # 元のパス等は@app.call(env)より前(=Wardenが介入する前)に取得しておく必要がある
      request = ActionDispatch::Request.new(env)
      path = request.fullpath
      ip = request.remote_ip
      user_agent = request.user_agent
      referer = request.referer

      status, headers, body = @app.call(env)

      if status == 401
        Rails.logger.info(
          "[unauthorized_request] path=#{path} ip=#{ip} " \
          "user_agent=#{user_agent.inspect} referer=#{referer.inspect}"
        )
      end

      [status, headers, body]
    end
  end
end
