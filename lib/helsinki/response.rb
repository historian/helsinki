class Helsinki::Response

  require 'digest/sha1'

  class << self
    attr_accessor :store
  end

  attr_reader :status, :headers, :body, :key
  attr_accessor :query_ids, :tables, :links, :includes, :digest

  def self.key_for(level, url)
    Digest::SHA1.hexdigest([level, url.normalize].join(':'))
  end

  def self.find(level_or_key, url=nil)
    key        = (url ? key_for(level_or_key, url) : level_or_key)
    attributes = store[key]
    new(attributes) if attributes
  end

  def self.build(level, url, status, headers, body)
    new(:level => level, :url => url, :status => status, :body => body)
  end

  def initialize(attributes={})
    @info      = attributes.dup
    @level     = @info.delete(:level)
    @url       = @info.delete(:url)
    @status    = @info.delete(:status)
    @headers   = @info.delete(:headers)
    @key       = @info.delete(:key)       || self.class.key_for(@level, @url)
    @query_ids = @info.delete(:query_ids) || []
    @tables    = @info.delete(:tables)    || Set.new
    @links     = @info.delete(:links)     || Set.new
    @includes  = @info.delete(:includes)  || Set.new
    @digest    = @info.delete(:digest)
    @original_digest = @digest
  end

  def [](key)
    @info[key.to_sym]
  end

  def []=(key, value)
    @info[key.to_sym] = value
  end

  def delete(key)
    @info.delete(key.to_sym)
  end

  def store
    self.class.store
  end

  def body_path
    store.body_path_for(@key)
  end

  def body(mode='r')
    if block_given?
      File.open(body_path, mode) do |file|
        yield(file)
      end

    else
      File.read(body_path)

    end
  end

  def each
    body do |file|
      file.each { |line| yield(line) }
    end
  end

  def calculate_digest
    digests = ""

    @query_ids.inject(digests) do |memo, query_id|
      memo.concat store.query_digest(query_id)
      memo
    end

    @includes.inject(digests) do |memo, fragment_id|
      memo.concat store.fragment_digest(fragment_id)
      memo
    end

    @digest = Digest::SHA1.hexdigest(digests)
  end


end