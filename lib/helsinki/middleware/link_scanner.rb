class Helsinki::Middleware::LinkScanner

  def initialize(app, queue, map)
    @app, @queue, @map = app, queue, map
  end

  def call(env)
    self.dup._call(env)
  end

  def _call(env)
    resp = @app.call(env)
    status, headers, body = *resp

    unless Helsinki::Body === body \
      headers['Content-Type'].starts_with?('text/html')
      return resp
    end

    body.processor method(:process)

    resp
  end

  TAG  = /[<](?:a|img|link|script)[^>]+[>]/i
  ATTR = /(?:href|src)[=]["]((?:\\.|[^"\\]+)+)["]/i

  def process(chunk, page)
    chunk.scan(TAG) do |a|
      next unless a =~ ATTR
      new_url = @map.normalize_url($1, @url)

      next unless @map.include?(new_url)
      @queue.push(new_url)

      # next unless Helsinki::Body === body
      # body.record.links_to.create :url => new_url
    end
    chunk
  end

end
