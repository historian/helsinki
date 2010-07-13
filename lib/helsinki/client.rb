class Helsinki::Client < EM::Connection
  include EM::P::ObjectProtocol

  def stop_server(&block)
    @callback = block
    send_object :type => :stop
  end

  def restart_server(&block)
    @callback = block
    send_object :type => :restart
  end

  def load(app, env, &block)
    @callback = block
    send_object :type => :load, :app => app, :env => env
  end

  def unload(app, &block)
    @callback = block
    send_object :type => :unload, :app => app
  end

  def build(app, &block)
    @callback = block
    send_object :type => :build, :app => app
  end

  def receive_object(obj)
    if @callback
      @callback.call(obj)
      @callback = nil
    end
  end

  def unbind
    EM.stop_event_loop
  end

end