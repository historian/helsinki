class Helsinki::Server < EventMachine::Connection

  include EM::P::ObjectProtocol

  @@config  = { 'applications' => {} }
  @@workers = {}
  @@pending_workers = {}

  def initialize(options)
    @options = options
    @@config = YAML.load(options.config) if File.file?(options.config)
    super
  end

  def receive_object(obj)
    case obj[:type]
    when :restart then restart
    when :stop    then stop
    when :load    then load(obj)
    when :unload  then unload(obj)
    when :build   then build(obj)

    when :hello   then
      @app = @@pending_workers.delete(obj[:token])
      msg = @@workers[@app]
      @@workers[@app] = self
      send_object msg
    end
  end

  def unbind
    @@workers.delete(@app) if @app
  end

  def stop
    send_object true
    close_connection_after_writing
    EM.next_tick { EM.stop_event_loop }
  end

  def restart
    cmd  = "#{File.expand_path($cmd)} start "
    cmd += "--socket=#{@options.socket.inspect} "
    cmd += "--config=#{@options.config.inspect} "
    cmd += "--foreground" if @options.foreground
    at_exit { exec(cmd) }
    send_object true
    close_connection_after_writing
    EM.next_tick { EM.stop_event_loop }
  end

  def load(obj)
    app, env = obj[:app], obj[:env]
    @@config['applications'][app] = { 'env' => env }
    puts "Loaded #{app} env:#{env}"
    send_object true
    close_connection_after_writing
  end

  def unload(obj)
    app = obj[:app]
    @@config['applications'].delete(app)
    puts "Unloaded #{app}"
    send_object true
    close_connection_after_writing
  end

  def build(obj)
    app = obj[:app]
    send_object true
    close_connection_after_writing

    if worker = @@workers[app]
      worker.send_object(obj)
    else
      token = Helsinki::Worker.spawn(
        @options.socket, app, @@config['applications'][app])
      @@pending_workers[token] = app
      @@workers[app] = obj
    end
  end

end