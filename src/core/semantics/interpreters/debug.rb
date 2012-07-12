require 'core/semantics/code/combinators'

module Debug
  extend Wrap

  def initialize
    @breakpts = []
    @level=0
    @stoplevel=1
  end

#  def _add_breakpoint(path)
#    @breakpts << path
#  end

  #TODO: Fix stoplevel logic. should be push-pop semantics instead of global var
  def execute_?(type, fields, args={})
    @level||=0; @stoplevel||=1; @breakpts||=[]; 
    @level +=1
    this = @obj
    if @level<=@stoplevel or @breakpts.include?(this._origin)
      #print some debugging info
      line = this._origin.start_line-1
          #TODO: $file is global var for efficiency reasons, should not be like this
      sample = $file[line][this._origin.start_column..(this._origin.start_line==this._origin.end_line ? this._origin.end_column : -2)]
      $stderr << "\n\nin #{this.schema_class.name}:\"#{sample[0..30]}\"  .eval(#{args[:env]}) ...\n"
           #TODO: the "args[:env]" has to go when not evaluating expressions
           #TODO: change this to a customizable debug message?
      line = this._origin.start_line-1
      $stderr << $file[[line-3,0].max..[line-1,0].max].map{|s|"     #{s}"}.join unless line==0
      $stderr << "   >>"+$file[line]
      $stderr << $file[line+1..line+3].map{|s|"     #{s}"}.join
      $stderr << "? "
      #await user instruction
      case read_char
      when "q" #q = quit
        exit(1)
      when "\e[A" #Up arrow = step out
        @stoplevel=@level-1
      when "\e[B" #Down arrow = step in
        @stoplevel=@level+1
      when "\e[C" #Right arrow = step over
        @stoplevel=@level
      when " " #space = resume
        @stoplevel=0
      else #default is to step in
        @stoplevel=@level+1
      end
      res = yield
      @stoplevel=[@stoplevel, @level].min #TODO: this is definitely the wrong approach
      $stderr << "=> #{res}\n\n"
    else
      res = yield
    end
    @level-=1
    res
  end

  #Constants and variables will be dispatched here and summarily ignored
  #(because they are too low-level)
  def execute_EConst(args={}); yield; end
  def execute_EVar(args={}); yield; end
end

# 'Lightweight' version of Debug that only print logging lines
module PrintWrap
  extend Wrap
  def execute_?(fields, type, args={})
    indent = (args[:indent]||0)
    puts "#{"  "*indent}evaling #{@obj}:#{type}"
    res = yield :indent=>indent+1
    puts "#{"  "*indent}-> #{res}"
    res
  end
end

def read_char
  begin
    system("stty raw -echo")
    str = STDIN.getc
  ensure
    system("stty -raw echo")
  end
  p str.chr
end
