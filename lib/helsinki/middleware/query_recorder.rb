class Helsinki::Middleware::QueryRecorder

  def initialize(app, recorder)
    @app, @recorder = app, recorder
    @cache = {}
  end

  def call(env)
    self.dup._call(env)
  end

  def _call(env)
    @recorder.start

    resp = @app.call(env)
    status, headers, body = *resp
    return resp unless Helsinki::Body === body

    @recorder.queries.each do |sql|
      query = Helsinki::Store::Query.first(:sql => sql)

      if query
        body.record.queries << query
      else
        digest = @recorder.digest(sql)
        body.record.queries.create :sql => sql, :digest => digest
      end
    end

    resp
  ensure
    @recorder.stop
  end

end
