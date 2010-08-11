require "test_helper"
require "test/unit"
require "resample"
require "resample/cli"
require "resample/gmdata"
require "resample/errors"
require "ostruct"

class TestOptions < Test::Unit::TestCase
  
  def test_control_file
    # should be able to correctly identify control file
    ctl_file = "ctl.txt"
    # first short option flag '-c'
    pm = GMResamplerProgramManager.new(["-c", ctl_file])
    options = pm.instance_variable_get :@options
    assert_equal(ctl_file, File.basename(options.control_file_name))
    # then long option flag '--control-file'
    pm = GMResamplerProgramManager.new(["--control-file", ctl_file])
    options = pm.instance_variable_get :@options
    assert_equal(ctl_file, File.basename(options.control_file_name))

    # should attempt to exit if no control file is given
    assert_raise SystemExit do
      silence_stream(STDOUT) { GMResamplerProgramManager.new(['-m', '*']) }
    end
    
  end
end

class TestResampler < Test::Unit::TestCase

  def test_file_matching
    test_file_dir = File.join(File.dirname(__FILE__), 'test_files', '6_files_and_ctl')
    options = OpenStruct.new
    options.directory = test_file_dir
    options.file_match = '*'
    options.output_dir = Dir.tmpdir
    options.control_file_name = File.join(test_file_dir, 'ctl.txt')
    rs = silence_stream(STDOUT) { GMResampler.new(options) }
    samples = rs.instance_variable_get :@samples
    # there should be 6 samples
    assert_equal(6, samples.length)
    samples.each { |s| assert_instance_of( GMSample, s ) }

    # file-matching more complicated than '*' has failed in the past
    options.file_match = '*.prn'
    rs = silence_stream(STDOUT) { GMResampler.new(options) }
    samples = rs.instance_variable_get :@samples
    # there should be 6 samples
    assert_equal(6, samples.length)
    samples.each { |s| assert_instance_of( GMSample, s ) }

    Dir.chdir(File.join(File.dirname(__FILE__), 'test_files', '6_files_and_ctl')) do
      options.directory = Dir.getwd
      options.file_match = '*.prn'
      options.control_file_name = File.join(options.directory, 'ctl.txt')
      rs = silence_stream(STDOUT) { GMResampler.new(options) }
      samples = rs.instance_variable_get :@samples
      # there should be 6 samples
      assert_equal(6, samples.length)
      samples.each { |s| assert_instance_of( GMSample, s ) }
    end

    # make sure that something that shouldn't work, doesn't
    options.file_match = '*.txt'
    rs = silence_stream(STDOUT) { GMResampler.new(options) }
    samples = rs.instance_variable_get :@samples
    # there should be 6 samples
    assert_not_equal(6, samples.length)
  end

end
