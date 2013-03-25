
require 'core/semantics/code/interpreter'

module Debug
  module Debug
    include Interpreter::Dispatcher

    def initialize
      super
      @stoplevel=1
      @breakpts=[]
      @watchlist=[]
      @viewwidth=10
      @file = nil
    end

    def debug_?(obj, &block)
      args = @D
      this = args[:this]
      stack = args[:stack] + ["in #{this}"]
      if (stack.size<=@stoplevel or @breakpts.include?(this._path))
        @file ||= begin; IO.readlines(this._origin.path); rescue; end
        ready = false
        while !ready
          ready = true
 
          #print some debugging info
          sample = @file.nil? ? "-source file not available-" : (line = this._origin.start_line-1; @file[line][this._origin.start_column..(this._origin.start_line==this._origin.end_line ? this._origin.end_column : -2)])
          vars = @watchlist.select{|v|args[v.to_sym]}.map{|v|"#{v}=#{args[v.to_sym]}"}.join(", ")
          $stderr << "\n\nin L#{stack.size}. #{this}:\"#{sample[0..30]}\"  #{args[:op]}(#{vars})\n"
               #TODO: change this to a customizable debug message?
          $stderr << "--------------------------------------------\n"
          if @file.nil?
            $stderr << "source file #{begin; this._origin.path; rescue; end} not available"
          else
            line = this._origin.start_line-1
            $stderr << @file[[line-@viewwidth,0].max..[line-1,0].max].map{|s|"     #{s}"}.join unless line==0
            $stderr << "   >>"+@file[line]
            $stderr << @file[line+1..line+@viewwidth].map{|s|"     #{s}"}.join
          end
          $stderr << "\n--------------------------------------------\n"
  
          #await user instruction
          $stderr << "(? for help): "
          case read_char
          when "q" #q = quit
            exit(1)
          when "5" #Down arrow = step in
            @stoplevel=stack.size+1
          when "6" #Right arrow = step over
            @stoplevel=stack.size
          when "7" #Up arrow = step out
            @stoplevel=stack.size-1
          when " ", "8" #space = resume
            @stoplevel=0
          when "w"
            $stderr << "Currently watching: #{@watchlist.map{|sym|sym.to_s}.join(", ")}\n"
            $stderr << "Available: #{(args.keys-@watchlist).map{|sym|sym.to_s}.join(", ")}\n"
            $stderr << "add (+) or remove (-)? "; op=read_char
            if op=="+"
              $stderr << "Which variable? "
              @watchlist << gets[0..-2].to_sym
            elsif op=="-"
              $stderr << "Which variable? "
              @watchlist.delete gets[0..-2].to_sym
            else
              $stderr << "Enter '+' or '-' only!\n\n"
            end
            ready = false
          when "s"
            $stderr << "Currently stack: \n"
            stack.each {|s| $stderr << "  #{s}\n"}
            ready = false
          when "v"
            $stderr << "New view width? "
            @viewwidth = gets[0..-2].to_i
            ready = false
          when "?"
            puts 
            puts "Commands: 5-step in, 6-step over, 7-step out, space-resume, q-quit"
            puts "          w-watch variable, b-breakpoints, s-print stack"
            puts "          v-change view width"
            puts
            ready = false
          else
            puts "Unrecognized command\n"
            ready = false
          end
        end
        res = dynamic_bind stack: stack do
          block.call
        end
        $stderr << "=> #{res}  (from L#{stack.size})\n\n"
        res
      else
        dynamic_bind stack: stack do
          block.call
        end
      end
    end
# 
    # def debug_?(obj, &block)
      # args = @D
      # this = args[:this]
      # stack = args[:stack] + ["in #{this}"]
      # if (@breakpts.include?(this._path)); end
# #      if (stack.size<=@stoplevel or @breakpts.include?(this._path))
# #      end
      # yield
    # end

    def read_char
      begin
        system("stty raw -echo")
        str = STDIN.getc
      ensure
        system("stty -raw echo")
      end
      p str.chr
    end
  end

  class DebugEvalExprC
    include Eval::EvalExpr
    include Debug
    def eval(obj)
      wrap(:eval, :debug, obj)
    end
  end

end

