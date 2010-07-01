class Helsinki::Middleware::Cache

  def initialize(app)
    @app = app
  end

  def call(env)
    self.dup._call(env)
  end

  def _call(env)
    status, headers, body = *@app.call(env)

    unless env['helsinki.active'] \
       and status.to_i == 200     \
       and headers['Content-Type'].starts_with?('text/html')
      return [status, headers, body]
    end

    env['helsinki.metadata'] = {
      'queries' => env['helsinki.queries']
    }
    env['helsinki.cache'].store(env, [status, headers, body])

    true
  end

end