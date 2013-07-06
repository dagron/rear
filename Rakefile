require 'rake'
require 'bundler/gem_helper'
require './test/helpers'
require './test/setup'

def run orm, message = nil
  
  require './test/models/%s' % orm
  Dir['./test/test__*.rb'].each { |f| require f }
  Rear.mount! # initializing Rear controllers
  puts message

  session = Specular.new
  session.boot { include Sonar }
  session.before do |app|
    include EASpecHelpers
    if app && EUtils.is_app?(app)
      app.mount
      app(app)
      map(app.base_url)
      app.ipp(1000) if app.respond_to?(:ipp)
    end
  end
  session.run /RearTest/
  puts session.failures if session.failed?
  puts session.summary
  exit session.exit_code
end

def run_ar
  run :ar, "\n***\n  Running ActiveRecord tests ..."
end

def run_dm
  run :dm, "\n***\n  Running DataMapper tests ..."
end

def run_sq
  run :sq, "\n***\n  Running Sequel tests ..."
end

desc 'Run ActiveRecord tests'
task('test:ar') { run_ar }

desc 'Run DataMapper tests'
task('test:dm') { run_dm }

desc 'Run Sequel tests'
task('test:sq') { run_sq }

desc 'Run All tests'
task :test do
  exitcode = 0
  (pid = fork { run_ar }) && Process.wait(pid); exitcode += $?.exitstatus
  (pid = fork { run_dm }) && Process.wait(pid); exitcode += $?.exitstatus
  (pid = fork { run_sq }) && Process.wait(pid); exitcode += $?.exitstatus
  exitcode == 0 || fail
end

namespace :assets do
  desc 'Update css files to correctly load background images'
  task :css do
    puts "Looking for css files containing background(-image)?:url ..."
    src = /background(\-image)?[\s+]?\:(.*?)url\((\W+)?([^\.]*)\.(\w+)(\W+)?\)/
    dst = 'background\1:\2url(\3\4.\5%s\6)' % RearConstants::ASSETS__SUFFIX
    Dir[File.expand_path('../assets/**/*.css', __FILE__)].each do |file|
      css = File.read(file)
      if css =~ src
        puts "Updating #{file}"
        File.open(file, 'w') {|f| f << css.gsub(src, dst)}
      end
    end
    puts "Done"
  end
end

task default: :test

Bundler::GemHelper.install_tasks
