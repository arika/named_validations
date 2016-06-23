# frozen_string_literal: true
require 'bundler/gem_tasks'
require 'rake/testtask'
require 'rubocop/rake_task'
require 'reek/rake/task'
require 'yard'
require 'yard/rake/yardoc_task'

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/**/*_test.rb']
end

RuboCop::RakeTask.new
Reek::Rake::Task.new
YARD::Rake::YardocTask.new

task default: %i(test rubocop reek)
