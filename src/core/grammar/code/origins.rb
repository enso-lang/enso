

class Origins
  attr_reader :path
  
  def initialize(source, path = '-')
    @path = path
    init_positions(source)
  end    

  def init_positions(source)
    @lines = []
    @columns = []
    line = 1
    column = 0
    source.each_char do |c|
      @lines << line
      @columns << column
      if c == "\n" then
        line += 1
        column = 0
      else 
        column += 1
      end
    end
    @lines << line
    @columns << -1 # eof
  end

  def column(pos)
    @columns[pos]
  end

  def line(pos)
    @lines[pos]
  end

  def str(pos)
    "line #{line(pos)} column #{column(pos)} (char #{pos + 1} in #{File.basename(@path)})"
  end

end
