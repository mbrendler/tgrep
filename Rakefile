# frozen_string_literal: true

require 'rake/testtask'
require 'rubocop/rake_task'

Rake::TestTask.new(:test) do |t|
  ENV['TESTOPTS'] = "#{ENV.fetch('TESTOPTS', nil)} #{ARGV.delete('--verbose')}"
  t.warning = true
  t.test_files = FileList['test/**/*_test.rb']
end

RuboCop::RakeTask.new

task default: %i[test rubocop]
