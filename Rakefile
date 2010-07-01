
desc "build the helsinki"
task :build do
  sh "gem build helsinki.gemspec"
  system('mkdir -p pkg ; mv ./*.gem pkg/')
end

desc "install the helsinki"
task :install => [:load_version, :build] do
  sh "gem install pkg/helsinki-#{Helsinki::VERSION}.gem"
end

desc "release the helsinki"
task :release => [:load_version, :build] do
  unless %x[ git status 2>&1 ].include?('nothing to commit (working directory clean)')
    puts "Your git stage is not clean!"
    exit(1)
  end

  if %x[ git tag 2>&1 ] =~ /^#{Regexp.escape(Helsinki::VERSION)}$/m
    puts "Please bump your version first!"
    exit(1)
  end

  require File.expand_path('../lib/helsinki/version', __FILE__)
  sh "gem push pkg/helsinki-#{Helsinki::VERSION}.gem"
  sh "git tag -a -m \"#{Helsinki::VERSION}\" #{Helsinki::VERSION}"
  sh "git push origin master"
  sh "git push origin master --tags"
end

begin
  require 'yard'
  YARD::Rake::YardocTask.new do |t|
    t.files   = FileList['lib/**/*.rb'].to_a
    t.options = ['-m', 'markdown', '--files', FileList['documentation/*.markdown'].to_a.join(',')]
  end
rescue LoadError
  puts "YARD not available. Install it with: sudo gem install yard"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'test'
  test.pattern = 'test/**/*_test.rb'
  test.verbose = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/*_test.rb'
    test.rcov_opts = %w{--rails --exclude osx\/objc,gems\/,spec\/}
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

task :load_version do
  require File.expand_path('../lib/helsinki/version', __FILE__)
end