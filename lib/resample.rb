class Resample
  VERSION = '1.1.0'
  missing = '9999'
  class << self; attr_reader :missing; attr_writer :missing; end
end
