class Helsinki::Visitor

  def initialize(app)
    @app = app
    fetch_configuration
  end

  def fetch_configuration
    url = URI.parse('http://localhost/_helsinki/configuration')

    status, headers, body = *@app.call({
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
      'helsinki.active'   => true
    })

    unless status.to_i == 200
      raise "Invalid rack application"
    end

    @map   = body[:map]
    @store_config = body[:store_config]
  end

  def with_store
    if @store
      yield
    else
      begin
        @store = Helsinki::Store.new(@store_config)
        yield
      ensure
        @store.close
      end
    end
  end

  def visit_all!
    @queue = Helsinki::Queue.new
    @map.enqueue(@queue)

    puts "Regenerating all resources:"

    with_store do
      until @queue.empty?
        visit! @queue.pop
      end
    end
  end

  def visit!(url)
    with_store do
      puts "- [1] #{url}"

      rack_stack.call({
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
        'helsinki.url'      => url,
        'helsinki.map'      => @map,
        'helsinki.queue'    => @queue,
        'helsinki.store'    => @store,
        'helsinki.info'     => {}
      })
    end
  end

  def rack_stack
    @rack_stack ||= begin
      app = @app

      app = Helsinki::Middleware::LinkScanner.new(app)
      app = Helsinki::Middleware::QueryRecorder.new(app)
      app = Helsinki::Middleware::Cache.new(app, 1)
      app = Helsinki::Middleware::Assembler.new(app)
      app = Helsinki::Middleware::Cache.new(app, 2)

      app
    end
  end

end