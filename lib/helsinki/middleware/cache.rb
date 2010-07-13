class Helsinki::Middleware::Cache

  def initialize(app, level)
    @app, @level = app, level
  end

  def call(env)
    self.dup._call(env)
  end

  def _call(env)
    if cache = env['helsinki.store'].fetch(@level, env)
      return [
        cache['status'].to_s,
        YAML.load(cache['headers']),
        [YAML.load(cache['body'])],
      ]
    end

    status, headers, body = *@app.call(env)

    unless env['helsinki.active'] \
       and status.to_i == 200     \
       and headers['Content-Type'].starts_with?('text/html')
      return [status, headers, body]
    end

    env['helsinki.store'].store(@level, env, [status, headers, body])

    true
  end

end