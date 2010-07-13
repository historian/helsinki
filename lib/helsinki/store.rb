class Helsinki::Store

  require 'oklahoma_mixer'

  def initialize(options={})
    @public_root   = File.expand_path(options[:public_root] || 'public/cache', Dir.pwd)
    @database_path = File.expand_path(options[:database_path] || 'db/helsinki', Dir.pwd)
  end

  def query_index
    @query_index ||= QueryIndex.new(@database_path)
  end

  def fragment_index
    @fragment_index ||= FragmentIndex.new(@database_path)
  end

  def page_index
    @page_index ||= PageIndex.new(@database_path, @public_root)
  end

  class Index

    def initialize(db_root, name)
      @path = File.join(db_root, "#{name}.tcb")
    end

    def open
      OklahomaMixer.open(@path) do |db|
        @db = db

        yield(self)
      end
      self
    end

    def find(key)
      raise "Database not opened" unless @db
      record = @db[key.to_s]
      record.split("\000") if record
    end

    def select(range)
      raise "Database not opened" unless @db

      @db.each(range.begin) do |key, record|
        break if range.exclude_end? and key >= range.end

        record = record.split("\000")
        yield(key, record)

        break if key >= range.end
      end

      self
    end

    def each
      raise "Database not opened" unless @db

      @db.each do |key, record|
        record = record.split("\000")
        yield(key, record)
      end

      self
    end

    def store(key, record, dup=false)
      raise "Database not opened" unless @db
      @db.store(key.to_s, record.join("\000"), dup ? :dup : nil)
      self
    end

  end

  class QueryIndex < Index

    def initialize(db_root)
      super(db_root, :queries)
    end

  end

  class QueryDependencyIndex < Index

    def initialize(db_root)
      super(db_root, :query_dependencies)
    end

  end

  class FragmentIndex < Index

    def initialize(db_root)
      @fragment_root = File.join(db_root, 'fragments')
      super(db_root, :fragments)
    end

    def read(uuid)
      path = File.join(@fragment_root, uuid)
      if File.file?(path)
        File.read(path)
      end
    end

    def write(uuid, content)
      path = File.join(@fragment_root, uuid)
      File.open(path, 'w+', 0644) { |file| file.write path }
      uuid
    end

  end

  class PageIndex < Index

    def initialize(db_root, public_root)
      @page_root = public_root
      super(db_root, :pages)
    end

    def read(path)
      path = File.join(@page_root, path)
      File.read(path) if File.file?(path)
    end

    def write(path, content)
      path = File.join(@page_root, path)
      File.open(path, 'w+', 0644) { |file| file.write path }
      path
    end

  end

end
