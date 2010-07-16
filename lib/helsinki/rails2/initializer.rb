require 'helsinki/map'

module Rails

  def self.helsinki
    @helsinki ||= Helsinki::Configuration.instance
  end

end

Rails.public_path = File.expand_path('app/assets', Rails.root.to_s)
Helsinki::QueryRecorder::ActiveRecord.inject!
Helsinki::Configuration.recorder = Helsinki::QueryRecorder.new

require File.join(Rails.root, 'config/helsinki.rb')
