class Helsinki::Middleware::QueryRecorder

  def initialize(app)
    @app = app
    @cache = {}
  end

  def call(env)
    self.dup._call(env)
  end

  def _call(env)
    queries = []

    notifier     = ActiveSupport::Notifications
    subscription = notifier.subscribe(/sql\.active_record/) do |*args|
      event = ActiveSupport::Notifications::Event.new(*args)
      sql   = event.payload[:sql]
      queries << sql if sql =~ /^\s*SELECT/i
    end

    resp = @app.call(env)
    status, headers, body = *resp
    return resp unless Helsinki::Body === body

    queries.each do |sql|
      query = Helsinki::Store::Query.find(:sql => sql)

      if query
        body.record.queries << query
      else
        rows   = ActiveRecord::Base.connection.select_rows(sql)
        digest = Digest::SHA1.hexdigest(Marshal.dump(rows))
        body.record.queries.create :sql => sql, :digest => digest
      end
    end

    resp
  ensure
    notifier.unsubscribe(subscription)
  end

end
