class Helsinki::QueryRecorder

  attr_reader :queries

  def start
    @queries = Set.new

    notifier      = ActiveSupport::Notifications
    @subscription = notifier.subscribe(/sql\.active_record/) do |*args|
      event = ActiveSupport::Notifications::Event.new(*args)
      sql   = event.payload[:sql]
      @queries << sql if sql =~ /^\s*SELECT/i
    end
  end

  def stop
    notifier = ActiveSupport::Notifications
    notifier.unsubscribe(@subscription)
  ensure
    @subscription = nil
    @queries = nil
  end

  def digest(sql)
    rows   = ActiveRecord::Base.connection.select_rows(sql)
    Digest::SHA1.hexdigest(Marshal.dump(rows))
  end

end
