
class Location
  attr_reader :path, :offset, :length, :start_line, :start_column, :end_line, :end_column

  def initialize(path, offset, length, start_line, start_column, end_line, end_column)
    @path = path
    @offset = offset
    @length = length
    @start_line = start_line
    @start_column = start_column
    @end_line = end_line
    @end_column = end_column
  end

  def to_s
    "line #{start_line} column #{start_column} [#{length}] (#{File.basename(path)})"
  end

  def inspect
    "<#{path}: from line #{start_line} and col #{start_column}, to line #{end_line} and col #{end_column}, at #{offset}, length = #{length}>"
  end

end
