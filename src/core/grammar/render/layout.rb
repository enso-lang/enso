require 'core/grammar/render/render'

class DisplayFormat < Dispatch
  def initialize(output)
    super()
    @output = output
  end

  def self.print(grammar, obj, width = 80, output=$stdout, slash_keywords = true)
    layout = Render(grammar, obj, slash_keywords)
    #pp layout
    DisplayFormat.new(output).print(layout)
    output << "\n"
  end

  def initialize(out)
    @out = out
    @indent = 0
    @lines = 0
  end

  def print obj
    if obj == true
      # nothing
    elsif obj.is_a?(Array)
      obj.each {|x| print x}
    elsif obj.is_a?(String)
      if @lines > 0
        @out << ("\n" * @lines)
        @out << (" " * @indent)
        @lines = 0
      else
        @out << " " if @space
      end
      @out << obj
      @space = true
    elsif obj.NoSpace?
      @space = false
    elsif obj.Indent?
      @indent += 2 * obj.indent
    elsif obj.Break?
      @lines = [@lines, obj.lines].max
    else
      raise "Unknown format #{obj}"
    end
  end  
end


