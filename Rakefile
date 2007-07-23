require 'rake/testtask'
require 'rake/rdoctask'
require 'rake/clean'

lib_dir = File.expand_path('lib')
test_dir = File.expand_path('test')

Rake::RDocTask.new('rdoc') do |t|
  t.rdoc_files.include('README', 'lib/**/*.rb')
  t.main = 'README'
  t.title = 'Reader documentation'
end

Rake::TestTask.new('test') do |t|
  t.libs = [lib_dir, test_dir]
  t.pattern = "test/**/tc_*.rb"
  t.warning = true
end

CLOBBER.include('doc', '**/*~')
CLEAN.include('test/**/*.tmp')
