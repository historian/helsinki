class Helsinki::Store

  require 'dm-core'
  require 'dm-types'
  require 'dm-serializer'
  require 'dm-migrations'
  require 'digest/sha1'

  def self.database(path)
    @database ||= begin
                    db_exists = File.file?(path)
                    db = DataMapper.setup(:helsinki, "sqlite3://#{path}")
                    DataMapper.auto_migrate!(:helsinki) unless db_exists
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

  def path_for(type, url)
    url_digest = Digest::SHA1.hexdigest([type, url].join(':'))
    root = Pathname.new(Dir.pwd)
    Pathname.new(File.join(@private_root, url_digest)).relative_path_from(root)
  end

  def link(page)
    public_path = File.join(@public_root, page.url.path)

    if page.headers['Content-Type'].starts_with?('text/html')

      if public_path.ends_with?('/')
        public_path += "index.html"
      end

      unless File.extname(public_path) == '.html'
        public_path += ".html"
      end

    end

    FileUtils.mkdir_p(File.dirname(public_path))
    File.unlink(public_path) if File.symlink?(public_path)
    src = File.join(Dir.pwd, page.path.to_s)
    src = File.readlink(src) if File.symlink?(src)
    FileUtils.ln_s(src, public_path)
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

  class FragmentQuery
    include DataMapper::Resource
    include Common

    property :id, Serial

    belongs_to :query
    belongs_to :fragment
  end

  class FragmentPage
    include DataMapper::Resource
    include Common

    property :id, Serial

    belongs_to :fragment
    belongs_to :page
  end

  class Query
    include DataMapper::Resource
    include Common

    property :id,     Serial
    property :sql,    Text,   :required => true
    property :digest, String, :required => true

    has n, :fragment_queries
    has n, :fragments, :through => :fragment_queries
  end

  class Fragment
    include DataMapper::Resource
    include Common

    property :id,      Serial
    property :url,     URI,      :required => true
    property :status,  Integer,  :required => true
    property :headers, Object,   :required => true
    property :path,    FilePath, :required => true

    has n, :fragment_queries
    has n, :queries, :through => :fragment_queries
    has n, :fragment_pages
    has n, :pages,   :through => :fragment_pages
  end

  class Page
    include DataMapper::Resource
    include Common

    property :id,      Serial
    property :url,     URI,      :required => true
    property :status,  Integer,  :required => true
    property :headers, Object,   :required => true
    property :path,    FilePath, :required => true

    has n, :fragment_pages
    has n, :fragments, :through => :fragment_pages
  end

  DataMapper.finalize

end
