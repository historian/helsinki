module Helsinki::Middleware

  require 'helsinki/middleware/filter_cachables'
  require 'helsinki/middleware/base_cache'
  require 'helsinki/middleware/page_cache'
  require 'helsinki/middleware/fragment_cache'
  require 'helsinki/middleware/query_recorder'
  require 'helsinki/middleware/link_scanner'
  require 'helsinki/middleware/assembler'
  require 'helsinki/middleware/page_linker'
  require 'helsinki/middleware/static_files'

end
