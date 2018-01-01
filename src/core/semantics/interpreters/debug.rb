require 'core/semantics/code/interpreter'
require 'colored'

module Debug
  module Debug
    include Interpreter::Dispatcher

    def init
      super
      @stoplevel=1
      @breakpts=[]
      @watchlist=[]
      @viewwidth=7
      @file = nil
      @D._bind(:stack, [])
    end

    def get_from_file(file, start_row, end_row, start_col, end_col)
      file = file + ["\n"]
      filelen = file.length
      sl = [start_row, 0].max
      el = [end_row, filelen].min
      sc = start_col
      ec = end_col
      return "" if sl > el
      if sl == el
        if ec == 0
          return ""
        else
          file[sl][sc..ec-1]
        end
      else
        first = middle = last = ""
        first = file[sl][sc..-1]
        last = file[el][0..ec-1]
        if ec == 0
          last = ""
        end
        if el - sl < 2
          middle = ""
        else
          middle = file[sl+1..el-1].join
        end
        first + middle + last
      end
    end

    def debug_?(obj, &block)
      args = @D
      this = obj
      stack = args[:stack] + ["in #{this}"]
      if (stack.size<=@stoplevel or @breakpts.include?(this._path))
        begin
        	@file ||= IO.readlines(this._origin.path)
        rescue
        end
        ready = false
        while !ready
          ready = true
 
          #print some debugging info
          vars = @watchlist.select{|v|args[v.to_sym]}.map{|v|"#{v}=#{args[v.to_sym]}\n"}.join
          $stderr << "\n\nin L#{stack.size}. #{this}\n#{vars}\n"
               #TODO: change this to a customizable debug message?
          $stderr << "--------------------------------------------\n"
          if @file.nil?
            $stderr << "source file #{this._origin.path} not available"
          else
              src_indicator = "  >> "
              src_indent    = "     "
              curr_color     = :red
              sl = this._origin.start_line-1
              el = this._origin.end_line-1
              sc = this._origin.start_column
              ec = this._origin.end_column
              before_start = [sl-@viewwidth, 0].max
              before = get_from_file(@file, before_start, sl, 0, sc)
              $stderr << src_indent + before.split("\n", 100).join("\n"+src_indent)
              selected = get_from_file(@file, sl, [el, sl+@viewwidth*2+1].min, sc, ec).red
              selected = selected.split("\n", 100).join("\n"+src_indent)
              $stderr << selected
              if el > sl+@viewwidth*2+1
                $stderr << " ... ...\n".red
              end
              filelen = @file.length
              after_end = [[el+@viewwidth, before_start+@viewwidth*2+2].max, filelen-1].min #min window size is 15
              after = get_from_file(@file, el, after_end, ec, @file[filelen-1].length)
              $stderr << after.split("\n", 100).join("\n"+src_indent)
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
        #puts res.class
        #$stderr << "=> #{res}"
        $stderr << "=>  (from L#{stack.size})\n\n"
        res
      else
        dynamic_bind stack: stack do
          res = block.call
        end
      end
    end

    def read_char
      begin
        system("stty raw -echo")
        str = STDIN.getc
      rescue
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

