class Helsinki::Middleware::QueryRecorder

  def initialize(app)
    @app = app
  end

  def call(env)
    self.dup._call(env)
  end

  def _call(env)
    queries = env['helsinki.queries'] = Set.new

    notifier     = ActiveSupport::Notifications
    subscription = notifier.subscribe(/sql\.active_record/) do |*args|
      event = ActiveSupport::Notifications::Event.new(*args)
      sql   = event.payload[:sql]
      if sql =~ /^\s*SELECT/i
        queries << sql.squeeze(' ')
      end
    end

    @app.call(env)

  ensure
    notifier.unsubscribe(subscription)
  end

end