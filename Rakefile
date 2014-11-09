task :default => :test

desc "Run the tests"
task(:test) do 
  Dir['./test/**/test_*.rb'].each { |f| load f }
end
