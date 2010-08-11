$LOAD_PATH << File.expand_path( File.dirname(__FILE__) + '/../lib' )

require 'stringio'
require 'fileutils'
require 'tmpdir'

# Pulled from Rails source,
# Remains under original license and attribution
#
# Silences any stream for the duration of the block.
#
#   silence_stream(STDOUT) do
#     puts 'This will never be seen'
#   end
#
#   puts 'But this will'
#
# CREDIT: David Heinemeier Hansson

def silence_stream(*streams) #:yeild:
  on_hold = streams.collect{ |stream| stream.dup }
  streams.each do |stream|
    stream.reopen(RUBY_PLATFORM =~ /32/ ? 'NUL:' : '/dev/null')
    stream.sync = true
  end
  yield
ensure
  streams.each_with_index do |stream, i|
    stream.reopen(on_hold[i])
  end
end

