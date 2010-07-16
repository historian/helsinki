class Helsinki::Configuration

  def self.method_missing(m, *args, &block)
    if instance.respond_to?(m)
      instance.__send__(m, *args, &block)
    else
      super
    end
  end

  def self.instance
    @instance ||= new
  end

  attr_reader :database_path, :public_root, :private_root, :recorder, :map
  attr_writer :database_path, :public_root, :private_root, :recorder
  attr_accessor :static_root

  def initialize
    @map = Helsinki::Map.new
    @database_path = 'db/helsinki.db'
    @public_root   = 'public'
    @private_root  = 'db/cache'
    @static_root   = 'app/assets'
    @recorder      = nil
  end

  def draw(&block)
    @map.draw(&block)
  end

  def config
    yield(self)
  end

end
