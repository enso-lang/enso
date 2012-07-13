require 'core/semantics/code/combinators'

module Debug
  extend Wrap

  operation :debug

  def debug_?(type, fields, args={})
    level = args[:level]
    this = @this
    if level<=@@stoplevel or @@breakpts.include?(this._path)
      ready = false
      while !ready
        ready = true

        #print some debugging info
        line = this._origin.start_line-1
            #TODO: $file is global var for efficiency reasons, should not be like this
        sample = $file[line][this._origin.start_column..(this._origin.start_line==this._origin.end_line ? this._origin.end_column : -2)]
        vars = @@watchlist.select{|v|args[v.to_sym]}.map{|v|"#{v}=#{args[v.to_sym]}"}.join(", ")
        $stderr << "\n\nin L#{level}. #{this}:\"#{sample[0..30]}\"  .eval(#{vars})\n"
             #TODO: the "args[:env]" has to go when not evaluating expressions
             #TODO: change this to a customizable debug message?
        $stderr << "--------------------------------------------\n"
        line = this._origin.start_line-1
        $stderr << $file[[line-@@viewwidth,0].max..[line-1,0].max].map{|s|"     #{s}"}.join unless line==0
        $stderr << "   >>"+$file[line]
        $stderr << $file[line+1..line+@@viewwidth].map{|s|"     #{s}"}.join
        $stderr << "--------------------------------------------\n"

        #await user instruction
        $stderr << "(? for help): "
        case read_char
        when "q" #q = quit
          exit(1)
        when "5" #Down arrow = step in
          @@stoplevel=level+1
        when "6" #Right arrow = step over
          @@stoplevel=level
        when "7" #Up arrow = step out
          @@stoplevel=level-1
        when " ", "8" #space = resume
          @@stoplevel=0
        when "w"
          $stderr << "Currently watching: #{@@watchlist}\n"
          $stderr << "add (+) or remove (-)? "; op=read_char
          if op=="+"
            $stderr << "Which variable? "
            @@watchlist << gets[0..-2].to_sym
          elsif op=="-"
            $stderr << "Which variable? "
            @@watchlist.delete gets[0..-2].to_sym
          else
            $stderr << "Enter '+' or '-' only!\n\n"
          end
          ready = false
        when "v"
          $stderr << "New view width? "
          @@viewwidth = gets[0..-2].to_i
          ready = false
        when "?"
          puts 
          puts "Commands: 5-step in, 6-step over, 7-step out, space-resume, q-quit"
          puts "          w-watch variable, b-breakpoints, s-status"
          puts "          v-change view width"
          puts
          ready = false
        else
          puts "Unrecognized command\n"
          ready = false
        end
      end
      res = yield :level=>level+1
      $stderr << "=> #{res}  (from L#{level})\n\n"
      res
    else
      yield :level=>level+1
    end
  end

  #Constants and variables will be dispatched here and summarily ignored
  #(because they are too low-level)
  def debug_EConst(args={}); yield; end
  def debug_EVar(args={}); yield; end

  def __init
    @@stoplevel=1
    @@breakpts=[]
    @@watchlist=[]
    @@viewwidth=10
  end
  def __hidden_calls; super+[:debug]; end
  def __default_args; super+{:level=>1}; end
end

# 'Lightweight' version of Debug that only print logging lines
module PrintWrap
  extend Wrap

  operation :print

  def print_?(fields, type, args={})
    indent = args[:indent]
    puts "#{"  "*indent}evaling #{@obj}:#{type}"
    res = yield :indent=>indent+1
    puts "#{"  "*indent}-> #{res}"
    res
  end
  def __hidden_calls; super+[:print]; end
  def __default_args; super+{:indent=>0}; end
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
