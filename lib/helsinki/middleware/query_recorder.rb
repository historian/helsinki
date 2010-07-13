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

    response = @app.call(env)

    digests = ActiveSupport::OrderedHash.new
    queries.each do |sql|
      digests[sql] = digest(sql)
    end
    env['helsinki.info']['queries'] = digests

    tables = Set.new
    queries.each do |sql|
      sql =~ /FROM\s+["'`]?([^\s"'`]+)["'`]?/i
      tables << $1

      sql.scan(/JOIN\s+["'`]?([^\s"'`]+)["'`]?/i) do |m|
        tables << m[0]
      end
    end
    env['helsinki.info']['tables'] = tables.to_a

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