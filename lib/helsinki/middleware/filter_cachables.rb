class Helsinki::Middleware::FilterCachables

  def initialize(app)
    @app = app
  end

  def call(env)
    unless env['REQUEST_METHOD'] == 'GET'
      raise Helsinki::EntitySkip, 'not a GET request'
    end

    resp = @app.call(env)
    status, headers, body = *resp

    if IGNORE_STATUSES.include?(status.to_i)
      raise Helsinki::EntitySkip, "unacceptable status code (#{status})"
    end

    if headers['X-Helsinki-Skip'] == 'true'
      raise Helsinki::EntitySkip, "forced (X-Helsinki-Skip)"
    end

    resp
  end

  IGNORE_STATUSES = (0...200).to_a + (400...600).to_a
end
