class GMSample
  attr_accessor :label
  attr_reader :orientations
  
  def initialize
    @orientations = []
  end
  
  def add_orientation(o)
    @orientations.push o
  end
  
  def number_of_coordinates
    total = 0
    orientations.each { |o| total += o.number_of_coordinates }
    total
  end
  
  def write_to_dvlr(directory)
    File.open(File.join(directory, label + '.prn'), 'w') do |file|
      file.write "# #{label} (lines resampled)\n"
      orientations.each do |o|
        first_point = true
        o.points.each do |p|
          if p.missing_data?
            res = ((0...Resample.dimensions).collect { Resample.missing.ljust(15) }).join(" ")
          else
            res = (p.values.collect { |v| (format "%.4f", v).ljust(15) }).join(" ")
          end
          res += " #{p.label.ljust(15)}"
          if first_point
            res += " #{o.label}"
            first_point = false
          end
          file.write res + "\n"
        end # writing points
        o.lines.each do |l|
          file.write "\n"
          first_point = true
          l.points.each do |p|
            if l.missing_data?
              res = ((0...Resample.dimensions).collect { Resample.missing.ljust(15) }).join(" ")
            else
              res = (p.values.collect { |v| (format "%.4f", v).ljust(15) }).join(" ")
            end
            if first_point
              res += " #{l.label}"
              first_point = false
            end
            file.write res + "\n"
          end # writing points in a line
        end # writing lines
        file.write "\n"
      end # writing orientation
    end
  end
  
  def write_to_morph(directory)
    File.open(File.join(directory, label + '.prn'), 'w') do |file|
      file.write "1 1L #{number_of_coordinates} 1 #{Resample.missing} DIM=#{Resample.dimensions}\n"
      file.write "#{label}\n\n"
      orientations.each do |o|
        first_point = true
        o.points.each do |p|
          if p.missing_data?
            res = ((0...Resample.dimensions).collect { Resample.missing.ljust(15) }).join(" ")
          else
            res = (p.values.collect { |v| (format "%.4f", v).ljust(15) }).join(" ")
          end
          file.write res + "\n"
        end # writing points
        o.lines.each do |l|
          file.write "\n"
          first_point = true
          l.points.each do |p|
            if l.missing_data?
              res = ((0...Resample.dimensions).collect { Resample.missing.ljust(15) }).join(" ")
            else
              res = (p.values.collect { |v| (format "%.4f", v).ljust(15) }).join(" ")
            end
            file.write res + "\n"
          end # writing points in a line
        end # writing lines
        file.write "\n"
      end # writing orientation
    end
  end
  
  def info
    "Sample: #{label}\n" + (orientations.collect { |o| o.info }).join("")
  end
  
  def init_from_file(filename)
    self.label = File.basename(filename, '.*')
    all_entries = read_file(filename)
    process_entries(all_entries)
  end
  
  def read_file(filename)
    # one array entry for each line: [['x','y','z','label'],['x','y','z','label'],...]
    all_entries = []
    File.open(filename) do |file|
      # count line numbers so error messages can be informative
      line_number = 0
      while line = file.gets
        line_number += 1
        # skip comment lines
        next if line =~ /^#/
        entries = line.split
        # skip empty lines
        next if entries.length == 0
        # 3,4,5 are the only valid lengths in a 3D file
        if entries.length < (Resample.dimensions) or entries.length > (Resample.dimensions + 2)
          GMErrorHandler.notice 3, "Skipping file #{filename}, line #{line_number} is not correctly formatted."
          raise GMFileFormatError
        end # error check
        # if we've made it this far the current line seems to be valid, add it to the 
        #   all_entries and entries_sizes arrays
        all_entries.push entries
      end # while
    end # file block
    all_entries
  end
  
  def process_entries(entries)
    curr_orientation = nil
    entries_sizes = entries.collect { |e| e.length }
    # if no line has Resample.dimensions+2 entries, there is only one orientation in the file
    if !(entries_sizes.include?(Resample.dimensions+2))
      curr_orientation = GMOrientation.new
      curr_orientation.label = nil
    # if there are multiple orientations, the first orientation must start on the first data line
    elsif entries_sizes[0] != (Resample.dimensions+2)
      GMErrorHandler.notice 3, "Skipping file #{filename}, the first orientation does not start on the first data line."
      raise GMFileFormatError
    end
    curr_line = nil
    (0..entries.length).to_a.each do |i|
      # FIRST, special case of starting a new orientation
      if entries_sizes[i] == (Resample.dimensions+2)
        # if there is an open line, add it to curr_orientation
        if curr_line and curr_orientation
          curr_orientation.add_line curr_line 
          curr_line = nil
        end
        if !curr_orientation.nil? then add_orientation curr_orientation end
        curr_orientation = GMOrientation.new
        curr_orientation.label = entries[i][-1]
        # if the next entry size is Resample.dimensions,
        #   we're starting a line
        if (entries_sizes[i+1] == Resample.dimensions)
          curr_line = GMLine.new
          curr_line.label = entries[i][-2]
          curr_line.add_point GMPoint.new.init(entries[i][0...Resample.dimensions])
        # otherwise we're just adding a point
        else 
          curr_orientation.add_point GMPoint.new.init(entries[i][0...Resample.dimensions], entries[i][-2])
        end
      # SECOND, inside an orientation 
      # if the current entry is size Resample.dimensions+1, we're adding either a new point or line
      elsif (entries_sizes[i] == (Resample.dimensions+1))
        if curr_line
          curr_orientation.add_line curr_line
          curr_line = nil
        end
        # if the next entry size is Resample.dimensions,
        #   we're starting a line
        if (entries_sizes[i+1] == Resample.dimensions)
          curr_line = GMLine.new
          curr_line.label = entries[i][-1]
          curr_line.add_point GMPoint.new.init(entries[i][0...Resample.dimensions])
        # otherwise we're just adding a point
        else 
          curr_orientation.add_point GMPoint.new.init(entries[i][0...Resample.dimensions], entries[i][-1])
        end
      # THIRD, adding a point to a line
      elsif (entries_sizes[i] == Resample.dimensions) and curr_line
        curr_line.add_point GMPoint.new.init(entries[i])
      end
    end
    # if there is an open line, add it to curr_orientation
    if curr_line and curr_orientation
      curr_orientation.add_line curr_line 
      curr_line = nil
    end
    # finally, add the final orientation if it exists
    if !curr_orientation.nil? then add_orientation curr_orientation end
  end
  
  def resample!(name, num)
    orientations.each { |o| o.resample!(name, num) }
  end
  
end # GMSample

class GMOrientation
  attr_accessor :label
  attr_reader :points, :lines
  
  def initialize
    @points = []
    @lines = []
  end
  
  def info
    points_missing_data_count = (points.select {|p| p.missing_data? }).length
    lines_missing_data_count = (lines.select {|l| l.missing_data? }).length
    res = <<-EOF
  #{label} orientation
    #{points.length} points (#{points_missing_data_count} missing data)
    #{lines.length} lines (#{lines_missing_data_count} missing data)
  EOF
    res
  end
  
  def number_of_coordinates
    total = 0
    points.each { |p| total += p.number_of_coordinates }
    lines.each { |l| total += l.number_of_coordinates }
    total
  end
  
  def add_line(l)
    @lines.push l
  end
  
  def add_point(point)
    @points.push point
  end
  
  def resample!(name, num)
    lines.each do |l| 
      if l.label == name 
        if num == 0
          lines.delete l
        else
          l.resample!(num) 
        end
      end
    end
  end
  
end

class GMPoint
  attr_accessor :label, :values
  
  # only used in the context of a line
  attr_accessor :delta_length
  attr_accessor :curve_length
  
  def initialize
    @missing_data = false
    self.delta_length = 0
    self.curve_length = 0
  end
  
  def number_of_coordinates
    values.length 
  end
  
  def missing_data?
    @missing_data
  end
    
  def init(points, name=nil)
    self.label = name
    self.values = points.collect { |e| (e == Resample.missing) ? nil : Float(e) }
    if values.include? nil then @missing_data = true end
    self
  end
  
  def to_s
    if @data_missing then return "#{label}: no data" end
    "#{label}: #{values.join(', ')}"
  end
  
end

class GMLine
  attr_accessor :label, :curve_length
  attr_reader :points
  
  def initialize
    @points = []
    self.curve_length = 0
    @missing_data = false
  end
  
  def missing_data?
    @missing_data
  end
  
  def number_of_coordinates
    total = 0
    points.each { |p| total += p.number_of_coordinates }
    total
  end
  
  def add_point(point)
    if point.missing_data? then @missing_data = true end
    if (@points.length > 0) and !@missing_data
      point.delta_length = pythagoras(point, @points[-1])
      @curve_length += point.delta_length
      point.curve_length = @curve_length
    end
    @points.push point
  end
  
  def pythagoras(p1,p2)
    squared_sum = 0
    (0...p1.values.length).to_a.each do |i|
      diff = p1.values[i] - p2.values[i]
      squared_sum += diff*diff
    end
    Math.sqrt(squared_sum)
  end
  
  def resample!(num)
    resampled_points = []
    if missing_data?
      values = (0...Resample.dimensions).collect { Resample.missing }
      num.times { resampled_points.push GMPoint.new.init(values) }
    else
      resampled_points.push @points[0]
      ratio = curve_length / (num - 1)
      along = ratio
      count = 0
      while count < (num - 2)
        after = 0
        while after < (@points.length - 1)
          break if @points[after].curve_length > along
          after += 1
        end
        # puts "after: #{after}, along: #{along}, curve length: #{curve_length}"
        # puts "   curve length before: #{@points[after-1].curve_length}, curve length after: #{@points[after].curve_length}"
        
        dd = along - @points[after-1].curve_length
        di = dd / @points[after].delta_length
        
        values = (0...Resample.dimensions).collect { |i| @points[after-1].values[i] + (di * (@points[after].values[i] - @points[after-1].values[i])) }
        resampled_points.push GMPoint.new.init(values)
        
        along += ratio
        count += 1
      end
      resampled_points.push @points[-1]
    end
    @points = []
    resampled_points.each { |p| add_point p }
  end
  
end

