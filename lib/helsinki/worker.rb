class Helsinki::Worker < EM::Connection

  require 'digest/sha1'
  require 'helsinki/map'
  require 'helsinki/queue'
  require 'helsinki/visitor'
  require 'helsinki/store'
  require 'helsinki/body'
  require 'helsinki/middleware'
  require 'helsinki/exceptions'

  include EM::P::ObjectProtocol

  def initialize(options, rack_app)
    @options  = options
    @rack_app = rack_app

    super
  end

  def post_init
  end

  def receive_object(obj)
    case obj[:type]
    when :ping    then ping
    when :restart then restart
    when :stop    then stop
    when :build   then build
    end
  end

  def ping
    send_object true
  end

  def restart
    cmd  = "#{File.expand_path($cmd)} start "
    cmd += "--dir=#{@options.dir.inspect} "
    cmd += "--env=#{@options.env.inspect} "
    cmd += "--sock=#{@options.sock.inspect} "
    cmd += "--foreground" if @options.foreground
    at_exit { exec(cmd) }
    send_object true
    EM.next_tick { EM.stop_event_loop }
  end

  def stop
    send_object true
    EM.next_tick { EM.stop_event_loop }
  end

  def build
    send_object true
    EM.next_tick { Helsinki::Visitor.new(@rack_app).visit_all! }
  end

end
