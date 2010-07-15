class Helsinki::Middleware::Assembler

  def initialize(app, visitor)
    @app, @visitor = app, visitor
  end

  def call(env)
    self.dup._call(env)
  end

  def _call(env)
    resp = @app.call(env)
    status, headers, body = *resp

    unless Helsinki::Body === body \
      and  headers['Content-Type'].starts_with?('text/html')
      return resp
    end

    @base_fragment = body.record
    @base_url      = env['helsinki.url']
    body.strategy  = :write
    body.processor method(:process)

    resp
  end

  INCLUDE_PATTERN = /[<][!][-][-]\s*include="((?:\\.|[^\\"])*)"\s*[-][-][>]/i

  def process(chunk, page)
    if @base_fragment
      page.fragments << @base_fragment
      @base_fragment = nil
    end

    chunk.gsub(INCLUDE_PATTERN) do |m|
      url = @base_url.merge($1)
      load_fragment! url, page
    end
  end

  def load_fragment!(url, page, redirect=0)
    status, headers, body = @visitor.visit_fragment!(url)

    case status
    when 200...300
      page.fragments << body.record if body.record
      body.read

    when 300...400
      page.fragments << body.record if body.record
      new_url = headers['Location']
      if new_url
        new_url = url.merge(new_url)
        if redirect >= 5
          "<!-- Too many redirects for: #{url} -->"
        else
          load_fragment!(new_url, page, redirect + 1)
        end

      else
        "<!-- No Location header: #{url}[#{status}]"
      end

    else
      "<!-- Load error: #{url}[#{status}] -->"

    end
  end

end
