class Resample
  VERSION = '1.1.0'
  @missing = '9999'
  @dimensions = 3
  class << self; attr_reader :missing; attr_writer :missing; end
  class << self; attr_reader :dimensions; attr_writer :dimensions; end
end
