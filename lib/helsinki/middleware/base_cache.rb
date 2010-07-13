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
      entity = model_class.find(:url => url)

      if entity
        headers = entity.headers.dup
        headers['X-Helsinki-Cached'] = 'true'
        [entity.status, headers, Helsinki::Body.new(entity.path, entity)]
      else
        resp = @app.call(env)
        resp[2] = Helsinki::Body.new(resp[2])
        resp
      end

    when :write
      resp = @app.call(env)
      status, headers, body = *resp

      if headers.delete('X-Helsinki-Cached') \
        or IGNORE_STATUSES.include?(status)
        resp[2] = Helsinki::Body.new(resp[2])
        return resp
      end

      entity = model_class.new(
        :url     => url,
        :status  => status,
        :headers => headers
      )

      entity.path = @store.write(cache_prefix, url, body, entity)
      entity.save!

      body = Helsinki::Body.new(entity.path, entity)

      return [status, headers, body]
    end
  end

  IGNORE_STATUSES = (0...200).to_a + (400...600).to_a

end
