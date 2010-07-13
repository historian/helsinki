class Helsinki::Visitor

  def initialize(app)
    @app = app
    fetch_configuration
  end

  def fetch_configuration
    url = URI.parse('http://localhost/_helsinki/configuration')

    status, headers, body = *@app.call(rack_env_for_url(url))

    unless status.to_i == 200
      raise "Invalid rack application"
    end

    @map   = body[:map]
    @queue = Helsinki::Queue.new
    @store = Helsinki::Store.new(body[:store_config])
    @store.setup!
  end

  def visit_all!
    @map.enqueue(@queue)

    puts "Regenerating all resources:"

    until @queue.empty?
      visit_page! @queue.pop
    end
  end

  def visit_page!(url)
    page_visitor_stack.call(rack_env_for_url(url))
  end

  def page_visitor_stack
    @page_visitor_stack ||= \
      begin
        app = lambda do |env|
          url = env['helsinki.url']
          visit_fragment!(url)
        end

        app = Helsinki::Middleware::Assembler.new(app, self)
        app = Helsinki::Middleware::LinkScanner.new(app, @queue, @map)
        app = Helsinki::Middleware::PageCache.new(app, @store, :write)

        app
      end
  end

  def visit_fragment!(url)
    fragment_visitor_stack.call(rack_env_for_url(url))
  end

  def fragment_visitor_stack
    @fragment_visitor_stack ||= \
      begin
        app = @app

        app = Helsinki::Middleware::FragmentCache.new(app, @store, :write)
        app = Helsinki::Middleware::QueryRecorder.new(app)
        app = Helsinki::Middleware::FragmentCache.new(app, @store, :read)

        app
      end
  end

  def rack_env_for_url(url)
    {
      'REQUEST_METHOD'    => 'GET',
      'SCRIPT_NAME'       => '',
      'PATH_INFO'         => url.path,
      'QUERY_STRING'      => url.query,
      'SERVER_NAME'       => url.host,
      'SERVER_PORT'       => url.port.to_s,
      'rack.version'      => Rack::VERSION,
      'rack.url_scheme'   => url.scheme,
      'rack.input'        => StringIO.new,
      'rack.errors'       => $stderr,
      'rack.multithread'  => false,
      'rack.multiprocess' => false,
      'rack.run_once'     => false,
      'helsinki.active'   => true,
      'helsinki.url'      => url
    }
  end


end
