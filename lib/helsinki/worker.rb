class Helsinki::Worker < EM::Connection

  require 'digest/sha1'

  include EM::P::ObjectProtocol

  def self.spawn(sock, app, options)
    token = Digest::SHA1.hexdigest([sock, app, rand(1<<100)].join('::'))

    EM.next_tick do
      EM.fork_reactor do
        $0 = "Helsinki worker: #{app}"

        require 'rack'
        require 'helsinki/map'
        require 'helsinki/queue'
        require 'helsinki/visitor'
        require 'helsinki/store'
        require 'helsinki/body'
        require 'helsinki/middleware'

        EM.connect_unix_domain(sock, Helsinki::Worker, app, options, token)
      end
    end

    token
  end

  def initialize(app, options, token)
    @app, @options, @token = app, options, token

    Dir.chdir(app)
    rackup = File.join(app, 'config.ru')
    user   = Etc.getpwuid(File.stat(rackup).uid).name
    EM.set_effective_user(user)

    ENV['RACK_ENV'] = ENV['RAILS_ENV'] = options['env']
    @rack_app, _ = *Rack::Builder.parse_file(rackup)

    puts "Started worker for #{@app}"

    super
  end

  def post_init
    send_object :type => :hello, :token => @token
  end

  def receive_object(obj)
    case obj[:type]
    when :build
      Helsinki::Visitor.new(@rack_app).visit_all!

    end
  end

  def unbind
    EM.next_tick { EM.stop_event_loop }
  end

end
