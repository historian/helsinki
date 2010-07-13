class Helsinki::Store

  require 'dm-core'
  require 'dm-more'
  require 'dm-migrations'
  require 'digest/sha1'

  def self.database(path)
    @database ||= begin
                    db = DataMapper.setup(:helsinki, "sqlite3://#{path}")
                    DataMapper.auto_migrate!(:helsinki)
                    db
                  end
  end

  def initialize(options={})
    @public_root   = File.expand_path(options[:public_root]   || 'public',         Dir.pwd)
    @private_root  = File.expand_path(options[:private_root]  || 'db/cache',       Dir.pwd)
    @database_path = File.expand_path(options[:database_path] || 'db/helsinki.db', Dir.pwd)
  end

  def setup!
    FileUtils.mkdir_p(@public_root)
    FileUtils.mkdir_p(@private_root)
    @database = self.class.database(@database_path)
  end

  def write(type, url, body, context=nil)
    if body.respond_to?(:to_path)
      body.to_path
    else
      url_digest = Digest::SHA1.hexdigest([type, url].join(':'))
      path = File.join(@private_root, url_digest)
      File.open(path, 'w+', 0644) do |file|
        body.each(context) { |chunk| file.write chunk }
      end
      path
    end
  end

  module Common

    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def default_repository_name
        :helsinki
      end
    end

  end

  class Query
    include DataMapper::Resource
    include Common

    property :id,     Serial
    property :sql,    Text,   :required => true
    property :digest, String, :required => true

    has n, :fragments, :through => Resource
  end

  class Fragment
    include DataMapper::Resource
    include Common

    property :id,      Serial
    property :url,     URI,      :required => true
    property :status,  Integer,  :required => true
    property :headers, Object,   :required => true
    property :path,    FilePath, :required => true

    has n, :queries, :through => Resource
    has n, :pages,   :through => Resource
  end

  class Page
    include DataMapper::Resource
    include Common

    property :id,      Serial
    property :url,     URI,      :required => true
    property :status,  Integer,  :required => true
    property :headers, Object,   :required => true
    property :path,    FilePath, :required => true

    has n, :fragments, :through => Resource
  end

  DataMapper.finalize

end
