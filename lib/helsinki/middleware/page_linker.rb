class Helsinki::Middleware::PageLinker

  def initialize(app, store)
    @app, @store = app, store
  end

  def call(env)
    self.dup._call(env)
  end

  def _call(env)
    resp = @app.call(env)
    status, headers, body = *resp

    if Helsinki::Body === body and body.record
      @store.link(body.record)
    end

    resp
  end

end
