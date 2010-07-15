class Helsinki::QueryRecorder

  attr_reader :queries

  @@recorder = nil

  def self.push(sql)
    @@recorder.queries << sql if @@recorder
  end

  def self.ignore
    recorder = @@recorder
    yield
  ensure
    @@recorder = recorder
  end

  def start
    @queries = Set.new
    @@recorder = self
  end

  def stop
    @queries = nil
  end

  def digest(sql)
    Helsinki::QueryRecorder.ignore do
      rows   = ActiveRecord::Base.connection.select_rows(sql)
      Digest::SHA1.hexdigest(Marshal.dump(rows))
    end
  end

end

module Helsinki::QueryRecorder::ActiveRecord

  def self.inject!
    return if @injected
    @injected = true
    ActiveRecord::Base.connection.class_eval do
      include Helsinki::QueryRecorder::ActiveRecord
      alias_method_chain :select,      :helsinki
      alias_method_chain :select_rows, :helsinki
    end
  end

  def select_with_helsinki(sql, name = nil)
    Helsinki::QueryRecorder.push sql
    select_without_helsinki(sql, name)
  end

  def select_rows_with_helsinki(sql, name = nil)
    Helsinki::QueryRecorder.push sql
    select_rows_without_helsinki(sql, name)
  end

end
