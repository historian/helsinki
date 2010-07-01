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

    @url   = env['helsinki.url']
    @map   = env['helsinki.map']
    @queue = env['helsinki.queue']
    @body  = body

    [status, headers, self]
  end

  def each
    @body.each do |chunk|

      chunk.scan(/[<]a[^>]+[>]/) do |a|
        if a =~ /href[=]["]((?:\\.|[^"\\]+)+)["]/i
          new_url = @map.normalize_url($1, @url)

          if @map.include?(new_url)
            @queue.push(new_url)
          end

        end
      end

      yield(chunk)
    end
  end

end