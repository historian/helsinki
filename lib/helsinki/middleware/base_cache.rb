class Helsinki::Middleware::BaseCache

  def initialize(app, store, access)
    @app, @store, @access = app, store, access
  end

  def call(env)
    self.dup._call(env)
  end

  def model_class
    nil
  end

  def cache_prefix
    nil
  end

  def _call(env)
    case @access
    when :read
      url    = env['helsinki.url']
      entity = model_class.first(:url => url)

      if entity
        headers = entity.headers.dup
        [entity.status, headers, Helsinki::Body.new(entity.path, entity)]
      else
        @app.call(env)
      end

    when :write
      resp = @app.call(env)
      status, headers, body = *resp

      url    = env['helsinki.url']
      path   = @store.path_for(cache_prefix, url)
      entity = model_class.create!(
        :url     => url,
        :status  => status,
        :headers => headers,
        :path    => path
      )

      unless Helsinki::Body === body
        body = Helsinki::Body.new(body)
      end

      body = body.persist(path, entity)

      [status, headers, body]
    end
  end


end
