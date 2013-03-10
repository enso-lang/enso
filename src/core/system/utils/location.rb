
class Location
  attr_reader :path, :offset, :size, :start_line, :start_column, :end_line, :end_column

  def initialize(path, offset, size, start_line, start_column, end_line, end_column)
    @path = path
    @offset = offset
    @size = size
    @start_line = start_line
    @start_column = start_column
    @end_line = end_line
    @end_column = end_column
  end

  def to_s
    "line #{start_line} column #{start_column} [#{size}] (#{File.basename(path)})"
  end

  def inspect
    "<#{path}: from line #{start_line} and col #{start_column}, to line #{end_line} and col #{end_column}, at #{offset}, size = #{size}>"
  end

end
