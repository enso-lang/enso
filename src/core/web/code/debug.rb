

require 'core/system/load/load'
require 'core/web/code/dispatch'
require 'core/web/code/web'
require 'core/web/code/expr'
require 'core/web/code/render'
require 'core/web/code/module'
require 'core/web/code/env'
require 'core/web/code/actions'
require 'core/web/code/form'
require 'core/web/code/xhtml2txt'


require 'readline'
require 'logger'
require 'fiber' # needed for alive?
require 'colorize'

module Web::Eval
  
  class DebugRender < Render
    def eval(obj, *args)
      Fiber.yield(obj, *args)
      send(obj.schema_class.name, obj, *args)
    end
  end


  class Debugger
    attr_reader :web, :root

    def initialize(web, root, cmd = '')
      if web && root then
        load(web, root)
      end
      unless cmd.empty? 
        puts "EVALING: #{cmd}"
        eval_command(cmd)
      end
    end
    
    def start
      while buf = Readline.readline("> ", true)
        begin
          eval_command(buf)
        rescue => e
          puts e.message
          print e.backtrace.join("\n")
        end
      end
    end

    def eval_command(line)
      cmd, *args = line.split
      if cmd && respond_to?(cmd) then
        send(cmd, *args)
      end
    end

    def print_xml(elt)
      output = IO.popen("xmllint --format --dropdtd --html -", "w+") do |pipe| 
        XHTML2Text.render(elt, pipe)
        pipe.close_write 
        pipe.read 
      end
      puts output
    end

    def locate(name)
      Loader.find_model(name) do |path|
        return path
      end
    end

    def do_step
      obj, @current_env, _ = @fiber.resume
      org = obj._origin
      puts org
      region = @sources[File.basename(org.path)][org.offset - 1..org.offset - 1 + org.length - 1]
      puts region.red
    end

    ### Commands
    ## todo: scope this in a separate class < BasicObject



    def continue
      while @fiber.alive? do
        do_step
      end
    end


    def step
      if @fiber.alive? then
        do_step
      else
        puts 'terminated'
      end
    end

    def load(web, root)
      @web = Loader.load(web)
      @sources = {}
      @sources[web] = File.read(locate(web))
      @sources['prelude.web'] = File.read(locate('prelude.web'))
      @root = Loader.load(root)
      @toplevel = Env.root(@root, DefaultActions)
      mod_eval = Mod.new(@toplevel, @log)
      mod_eval.eval(@web)
      @log = Logger.new($stderr)
      @eval = DebugRender.new(Expr.new, @log)
    end

    def get(url)
      env = @toplevel
      @current_env = env.new
      call = Template.parse(url, @root, env)
      @errors = {}
      if call then
        @toplevel['errors'] = Record.new(@errors)
        @toplevel['self'] = call
        @output = []
        @fiber = Fiber.new do 
          call.invoke(@eval, @current_env, @output)
        end
      else
        puts "404: #{url}"
      end
    end

    def output
      @output.each do |elt|
        print_xml(elt)
      end
    end

    def env
      @current_env.each do |name, value|
        next if value.is_a?(Template) && value.args.nil?
        printf("\t%-20s: %s\n", name, value.inspect)
      end
    end

  end


end


if __FILE__ == $0 then
  debugger = Web::Eval::Debugger.new(ARGV[0], ARGV[1], ARGV[2..-1].join)
  debugger.start
end
