class Helsinki::Visitor

  def initialize(map, cache)
    @map   = map
    @cache = cache
  end

  def visit_all!
    @queue = Helsinki::Queue.new
    @map.enqueue(@queue)

    until @queue.empty?
      visit! @queue.pop
    end
  end

  def visit!(url)
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
      'helsinki.cache'    => @cache
    })
  end

  def rack_stack
    @rack_stack ||= begin
      app = Rails.application

      app = Helsinki::Middleware::LinkScanner.new(app)
      app = Helsinki::Middleware::QueryRecorder.new(app)
      app = Helsinki::Middleware::Cache.new(app)

      app
    end
  end

end