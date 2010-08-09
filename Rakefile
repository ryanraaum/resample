# -*- ruby -*-
# vim: syntax=ruby

require "rubygems"
require "rake"
require "rake/testtask"
require "rake/gempackagetask"
require "rake/rdoctask"
require "lib/resample"

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList["test/test_*.rb"]
  t.verbose = true
end

task :default => ["test"]

# This builds the actual gem. For details of what all these options
# mean, and other ones you can add, check the documentation here:
#
#   http://rubygems.org/read/chapter/20
#
spec = Gem::Specification.new do |s|

  # Change these as appropriate
  s.name              = "resample"
  s.version           = Resample::VERSION
  s.summary           = "Resample a curvilinear set of semi-landmarks into a user-prescribed set of evenly-spaced semi-landmarks."
  s.author            = "Ryan Raaum"
  s.email             = "ryan.raaum@gmail.com"
  s.homepage          = "http://github.com/ryanraaum/resample"

  s.has_rdoc          = true
  s.extra_rdoc_files  = %w(README.txt)
  s.rdoc_options      = %w(--main README.txt)

  # Add any extra files to include in the gem
  s.files             = %w(History.txt Manifest.txt Rakefile README.txt) + Dir.glob("{bin,test,lib/**/*}")
  s.executables       = FileList["bin/**"].map { |f| File.basename(f) }
  s.require_paths     = ["lib"]

  # If you want to depend on other gems, add them here, along with any
  # relevant versions
  # s.add_dependency("some_other_gem", "~> 0.1.0")

  # If your tests use any gems, include them here
  # s.add_development_dependency("mocha") # for example
end

# This task actually builds the gem. We also regenerate a static
# .gemspec file, which is useful if something (i.e. GitHub) will
# be automatically building a gem for this project. If you're not
# using GitHub, edit as appropriate.
#
# To publish your gem online, install the 'gemcutter' gem; Read more 
# about that here: http://gemcutter.org/pages/gem_docs
Rake::GemPackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
end

desc "Build the gemspec file #{spec.name}.gemspec"
task :gemspec do
  file = File.dirname(__FILE__) + "/#{spec.name}.gemspec"
  File.open(file, "w") {|f| f << spec.to_ruby }
end

task :package => :gemspec

# Generate documentation
Rake::RDocTask.new do |rd|
  rd.main = "README.txt"
  rd.rdoc_files.include("README.txt", "lib/**/*.rb")
  rd.rdoc_dir = "rdoc"
end

desc 'Clear out RDoc and generated packages'
task :clean => [:clobber_rdoc, :clobber_package] do
  rm "#{spec.name}.gemspec"
end
