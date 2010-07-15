class Helsinki::Middleware::FilterCachables

  def initialize(app)
    @app = app
  end

  def call(env)
    unless env['REQUEST_METHOD'] == 'GET'
      raise Helsinki::EntitySkip
    end

    resp = @app.call(env)
    status, headers, body = *resp

    if IGNORE_STATUSES.include?(status.to_i)
      raise Helsinki::EntitySkip
    end

    unless headers['Content-Length'] \
      or   headers['Transfer-Encoding'] == 'chunked'
      raise Helsinki::EntitySkip
    end

    if headers['X-Helsinki-Skip'] == 'true'
      raise Helsinki::EntitySkip
    end

    resp
  end

  IGNORE_STATUSES = (0...200).to_a + (400...600).to_a
end
