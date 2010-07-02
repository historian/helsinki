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
      if sql =~ /^\s*SELECT/i
        sql = sql.squeeze(' ').strip
        queries << sql
      end
    end

    response = @app.call(env)

    env['helsinki.queries'] = {}
    queries.each do |sql|
      env['helsinki.queries'][sql] = digest(sql)
    end

    response
  ensure
    notifier.unsubscribe(subscription)
  end

  def digest(sql)
    @cache[sql] ||= begin
      rows = ActiveRecord::Base.connection.select_rows(sql)
      Digest::SHA1.hexdigest(Marshal.dump(rows))
    end
  end

end