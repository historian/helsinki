class Helsinki::Middleware::LinkScanner

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

    @env  = env
    @body = body

    [status, headers, self]
  end

  INCLUDE_PATTERN = /[<][!][-][-]\s*include="((?:\\.|[^\\"])*)"\s*[-][-][>]/

  def each
    @body.each do |chunk|

      chunk = chunk.gsub(INCLUDE_PATTERN) do |m|
        url = env['helsinki.url'].merge($1)


      end

      yield(chunk)
    end
  end

  def subcall(env, url)

  end

end