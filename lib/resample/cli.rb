require 'ostruct'
require 'optparse'
require 'fileutils'

MSWIN = (RUBY_PLATFORM =~ /32/) or false

class GMResamplerProgramManager
  def initialize(args)
    @options = OpenStruct.new
    @options.directory = File.expand_path(Dir.getwd)
    @options.missing_data = '9999'
    @options.output_format = 'dvlr'
    @options.output_dir = File.expand_path(File.join(Dir.getwd,'resampled'))
    if MSWIN
       @options.file_match = "*.*"
    else
       @options.file_match = "*"
    end
    parse_argv(args)
  end
  
  def parse_argv(args)
    opts = OptionParser.new do |opts|
      if MSWIN
        opts.banner = "Usage: resample.exe [options]"
      else
        opts.banner = "Usage: resample [options]"
      end

      opts.separator ""
      opts.separator "Specific options:"

      # Mandatory argument.
      opts.on("-c", "--control-file CONTROL_FILE",
              "Resample lines as specified",
              "  in the CONTROL_FILE") do |cf|
        @options.control_file_name = File.expand_path(cf)
      end
      
      opts.on("-d", "--directory DIRECTORY",
              "Process files in DIRECTORY",
              "  (default: current directory)") do |d|
        @options.directory = File.expand_path(d)
      end
      
      if MSWIN
        opts.on("-e", "--extension FILE_EXTENSION",
                "Process files with FILE_EXTENSION",
                "  (default: *.*)") do |e|
          @options.file_match = "*.#{e}"
        end
      else
        opts.on("-e", "--extension FILE_EXTENSION",
                "Process files with FILE_EXTENSION",
                "  (default: *)") do |e|
          @options.file_match = "*.#{e}"
        end
      end
      
      opts.on("-o", "--output-directory DIRECTORY",
              "Write processed files to DIRECTORY",
              "  (default: current directory/resampled)") do |o|
        @options.output_dir = File.expand_path(o)
      end
      
      opts.on("-f", "--output-format FORMAT",
              "Write processed files for dvlr or morpheus",
              "  Options: dvlr|morph (default: dvlr)") do |f|
        @options.output_format = f
      end
      
      opts.on("-?", "--missing-data ID",
              "missing data is indicated by ID",
              "  (default: 9999)") do |d|
        @options.missing_data = d
        Resample.missing = d
      end

      opts.separator ""
      opts.separator "Common options:"

      # No argument, shows at tail.  This will print an options summary.
      # Try it and see!
      opts.on("-h", "--help", "Show this message") do
        puts opts
        exit
      end

      # Another typical switch to print the version.
      opts.on("-v", "--version", "Show version") do
        puts "Resample version " + Resample::VERSION + ", by Ryan Raaum, David Reddy, Johann Kim"
	      puts "Created for the NYCEP Morphometrics Group"
        exit
      end
      
      opts.separator ""
      opts.separator "Examples:"
      
      if MSWIN
        opts.on <<-EOF
    
    # process lines indicated in `ctl.txt` in all files 
    # located in the current directory  
    resample.exe -c ctl.txt
    
    # process all files with .prn extension in the current directory
    resample.exe -c ctl.txt -e prn
    
    # process all files in the given directory
    resample.exe -c ctl.txt -d "C:\\Lines"
    
    # process all files with .prn extension in the given directory
    resample.exe -c ctl.txt -d "C:\\Lines" -e prn
    
    EOF
      else
        opts.on <<-EOF
    
    # process lines indicated in `ctl.txt` in all files 
    #   located in the current directory 
    resample -c ctl.txt
 
    # process all files with .prn extension in the current directory
    resample -c ctl.txt -e prn
    
    # process all files in the given directory
    resample -c ctl.txt -d /Users/ryan/Documents/Lines
    
    # process all files with .prn extension in the given directory
    resample -c ctl.txt -d /Users/ryan/Documents/Lines -e prn
    
    EOF
      end

    end
    
    if args.length == 0
      puts opts
      exit
    end

    begin
      opts.parse!(args)
    rescue
    end

    if @options.control_file_name.nil?
      puts "ERROR. No control file given."
      exit
    end

    if @options.debug then $DEBUG=true end
      
    if !(['dvlr', 'morph'].include? @options.output_format)
      puts "ERROR. Invalid output format."
      exit
    end
      
  end
  
  def run
    # validate the existence of the control file
    if !File.exists? @options.control_file_name
      GMErrorHandler.handle 1, "ERROR. The control file '#{@options.control_file_name}' cannot be found."
    end
    if !File.directory? @options.directory
      GMErrorHandler.handle 1, "ERROR. '#{@options.directory}' is not a directory."
    end
    GMResampler.new(@options).run
  end
end

class GMResampler
  def initialize(options)
    files = Dir.glob(File.join(options.directory, options.file_match)).select { |f| !File.directory? f }
    @lines = parse_control_file(options.control_file_name)
    @output_format = options.output_format
    @output_dir = options.output_dir
    samples = files.collect do |f|
      curr = GMSample.new
      begin
        curr.init_from_file(f)
      rescue GMFileFormatError
        curr = nil
      end
      curr
    end
    # some samples could be nil if problems were encountered reading files, so select those out
    @samples = samples.select {|s| !s.nil? }
  end
  
  def parse_control_file(ctl_file_name)
    if !File.exists? ctl_file_name
      GMErrorHandler.handle 1, "ERROR. The control file '#{ctl_file_name}' cannot be found."
    end
    lines = {}
    File.open(ctl_file_name) do |file|
      line_number = 0
      while line = file.gets
        
        # do some error checking
        line_number += 1
        next if line =~ /^#/
        entries = line.split
        next if entries.length == 0
        if entries.length < 2 or !(entries[1] =~  /^[0-9]+$/)
          GMErrorHandler.handle 2, "ERROR. Control file, line #{line_number}: No resample number found."
        elsif entries.length > 2
          GMErrorHandler.handle 2, "ERROR. Control file, line #{line_number}: Too many items."
        end
        
        lines[entries[0]] = entries[1].to_i
      end
    end
    lines
  end
  
  def run
    @lines.each do |l|
      @samples.each do |s| 
        s.resample!(l[0], l[1])
      end 
    end
    # make output directory if necessary
    if !File.exists?(@output_dir) then FileUtils.mkdir(@output_dir) end
    @samples.each { |s| eval("s.write_to_#{@output_format} @output_dir") }
  end
end

