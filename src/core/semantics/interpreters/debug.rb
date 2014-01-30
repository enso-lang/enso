require 'core/semantics/code/interpreter'
require 'colored'

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
      this = obj #args[:this]
      stack = args[:stack] + ["in #{this}"]
      if (stack.size<=@stoplevel or @breakpts.include?(this._path))
        @file ||= begin; IO.readlines(this._origin.path); rescue; end
        ready = false
        while !ready
          ready = true
 
          #print some debugging info
          sample = @file.nil? ? "-source file not available-" : (line = this._origin.start_line-1; @file[line][this._origin.start_column..(this._origin.start_line==this._origin.end_line ? this._origin.end_column : -2)])
          vars = @watchlist.select{|v|args[v.to_sym]}.map{|v|"#{v}=#{args[v.to_sym]}"}.join("\n")
          $stderr << "\n\nin L#{stack.size}. #{this}:\"#{sample[0..30]}\"  #{args[:op]}\n#{vars}"
               #TODO: change this to a customizable debug message?
          $stderr << "--------------------------------------------\n"
          if @file.nil?
            $stderr << "source file #{begin; this._origin.path; rescue; end} not available"
          else
              src_indicator = "  >> "
              src_indent    = "     "
              curr_color     = :red
              sl = this._origin.start_line-1
              el = this._origin.end_line-1
              sc = this._origin.start_column
              ec = this._origin.end_column
              $stderr << @file[[sl-@viewwidth,0].max..[sl-1,0].max].map{|s|"     #{s}"}.join unless sl==0
              if sc == 0 and ec == 0
                $stderr << src_indicator + @file[sl..el].join(src_indent).red
              elsif sl == el
                $stderr << src_indicator
                $stderr << @file[sl][0..sc-1] if sc > 0
                $stderr << @file[sl][sc..ec-1].red + @file[sl][ec..-1]
              else
                first = middle = last = ""
                if sc == 0
                  first = src_indicator + @file[sl].red
                else 
                  first = src_indicator + @file[sl][0..sc-1] + @file[sl][sc..-1].red
                end
                if ec == 0
                  last = ""
                else
                  last = src_indent + @file[el][0..ec-1].red + @file[el][ec..-1]
                end
                if el - sl < 2
                  middle = ""
                else
                  middle = src_indent + @file[sl+1..el-1].join(src_indent).red
                end
                $stderr << first + middle + last
              end
              filelen = @file.length
              $stderr << @file[[el+1,filelen].min..[el+@viewwidth,filelen].min].map{|s|"     #{s}"}.join
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

