class Helsinki::Client

  def initialize(sock)
    @sock = sock
  end

  def ping(&block)
    exec(:ping, &block)
  end

  def restart(&block)
    exec(:restart, &block)
  end

  def stop(&block)
    exec(:stop, &block)
  end

  def build(&block)
    exec(:build, &block)
  end

  private

  def run_em
    if EM.reactor_running?
      @em_was_running     = true
      @stop_after_command = false
      yield
    else
      @em_was_running     = false
      @stop_after_command = true
      EM.run { yield }
    end
  end

  def connect
    if @connection
      run_em { yield }
    else
      run_em do
        @connection = EM.connect_unix_domain(@sock, Helsinki::Client::Connection, self)
        yield
      end
    end
  end

  def exec(command, *args)
    connect do
      @connection.__send__(command, *args) do |response|
        if !@em_was_running and !block_given?
          @response = response
        else
          yield(response)
        end
        EM.stop_event_loop if @stop_after_command
      end
    end
    @response || true
  rescue RuntimeError => e
    raise unless e.message.include?('no connection')
    return false
  end

  class Connection < EM::Connection
    include EM::P::ObjectProtocol

    def ping(&block)
      @callback = block
      send_object :type => :ping
    end

    def stop(&block)
      @callback = block
      send_object :type => :stop
    end

    def restart(&block)
      @callback = block
      send_object :type => :restart
    end

    def build(&block)
      @callback = block
      send_object :type => :build
    end

    def receive_object(obj)
      if @callback
        @callback.call(obj)
        @callback = nil
      end
    end

  end
end
