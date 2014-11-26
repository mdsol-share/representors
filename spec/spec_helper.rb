SPEC_DIR = File.expand_path("..", __FILE__)
lib_dir = File.expand_path("../lib", SPEC_DIR)

$LOAD_PATH.unshift(lib_dir)
$LOAD_PATH.uniq!

require 'rspec'
require 'debugger'
require 'bundler'
require 'simplecov'
require 'pry'

Debugger.start
Bundler.setup

require 'representors'

Dir["#{SPEC_DIR}/support/*.rb"].each { |f| require f }

def create_serializer(name)
  Class.new(Representors::SerializerBase) do |klass|
    klass.media_symbol name.to_sym
    klass.media_type name
  end
end

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random' unless ENV['RANDOMIZE'] == 'false'

  config.include Support::Helpers
  config.include RepresentorSupport::Utilities
end
