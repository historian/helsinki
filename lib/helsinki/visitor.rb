class Helsinki::Visitor

  def initialize(app)
    @app = app
    configure
  end

  def configure
    @map   = Helsinki::Configuration.map
    @queue = Helsinki::Queue.new
    @store = Helsinki::Store.new(:database_path => Helsinki::Configuration.database_path,
                                 :private_root  => Helsinki::Configuration.private_root,
                                 :public_root   => Helsinki::Configuration.public_root)
    @recorder = Helsinki::Configuration.recorder
    @static_root = Helsinki::Configuration.static_root
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
    puts "- #{url}"
    resp = page_visitor_stack.call(rack_env_for_url(url))
  rescue Helsinki::EntitySkip
    return :skip
  end

  def page_visitor_stack
    @page_visitor_stack ||= \
      begin
        app = lambda do |env|
          url = env['helsinki.url']
          resp = visit_fragment!(url)
          if resp == :skip
            raise Helsinki::EntitySkip
          end
          resp
        end

        app = Helsinki::Middleware::Assembler.new(app, self)
        app = Helsinki::Middleware::LinkScanner.new(app, @queue, @map)
        app = Helsinki::Middleware::PageCache.new(app, @store, :write)
        app = Helsinki::Middleware::PageLinker.new(app, @store)
        app = Helsinki::Middleware::PageCache.new(app, @store, :read)

        app
      end
  end

  def visit_fragment!(url)
    puts "  + #{url}"
    resp = fragment_visitor_stack.call(rack_env_for_url(url))
    puts "    [#{resp[0]}]"
    resp
  rescue Helsinki::EntitySkip => e
    puts "    [skip: #{e.message}]"
    return :skip
  end

  def fragment_visitor_stack
    @fragment_visitor_stack ||= \
      begin
        app = @app

        app = Helsinki::Middleware::StaticFiles.new(app, @static_root)
        app = Helsinki::Middleware::FilterCachables.new(app)
        app = Helsinki::Middleware::FragmentCache.new(app, @store, :write)
        app = Helsinki::Middleware::QueryRecorder.new(app, @recorder)
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
      'helsinki.url'      => url,
      'HTTP_HOST'         => "#{url.host}:#{url.port}"
    }
  end


end
