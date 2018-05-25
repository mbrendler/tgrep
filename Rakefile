# frozen_string_literal: true

require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  ENV['TESTOPTS'] = "#{ENV['TESTOPTS']} #{ARGV.delete('--verbose')}"
  t.warning = true
  t.test_files = FileList['test/**/*_test.rb']
end

task default: :test
