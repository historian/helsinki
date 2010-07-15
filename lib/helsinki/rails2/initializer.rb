class Rails::Configuration

  def helsinki
    Rails::Helsinki::Configuration.instance
  end

end

module Rails::Helsinki

  def self.mapping
    Rails.configuration.helsinki.mapping
  end

end

class Rails::Helsinki::Configuration

  attr_accessor \
    :mapping,
    :database_path,
    :public_root, :private_root

  def initialize
    @mapping = Helsinki::Map.new
    @database_path = 'db/helsinki.rb'
    @public_root   = 'public'
    @private_root  = 'db/cache'
  end

  def self.instance
    @instance ||= new
  end

end

Rails.configuration.after_initialize do
  Helsinki::QueryRecorder::ActiveRecord.inject!

  Rails.configuration.middleware.use 'Helsinki::ConfigurationMiddleware'

  # require File.join(Rails.root, 'config/helsinki.rb')
end
