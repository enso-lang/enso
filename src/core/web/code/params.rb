
require 'core/web/code/reference'


# TODO: distinguish between get params (is env like)
# and post params, which are updates.


module Web::Eval
  class Form
    attr_reader :actions

    def initialize(data)
      @bindings = {}
      @actions = []
      @variables = {}
      parse(flatten(data))
      puts "________: #{to_s}"
    end

    def each(&block)
      @bindings.each(&block)
    end

    def env
      @variables
    end
      

    def to_s
      s = "BINDINGS:\n"
      @bindings.each do |k, v|
        s << "\t#{k}:\t#{v}\n"
      end
      s << "ACTIONS:\n"
      @actions.each do |a|
        s << "\t#{a}\n"
      end      
      s << "VARIABLES:\n"
      @variables.each do |k, v|
        s << "\t#{k}:\t#{v}\n"
      end
      return s
    end

    private

    def flatten(hash)
      # I hate this.
      tbl = {}
      hash.each do |k, v|
        if v.is_a?(Hash) then
          flatten(v).each do |k2, v2|
            if k2 !~ /^\./ then
              ks = k2.split(/\./)
              tbl[k + "[" + ks.first + "]." + ks[1..-1].join('.')] = v2
            else
              tbl[k + k2] = v2
            end
          end
        else
          tbl[k] = v
        end
      end
      return tbl
    end

    def parse(hash)
      hash.each do |k, v|
        if k =~ /^!/ then 
          @actions << Action.make(k, v)
        elsif k =~ /^[@.]/ then
          lv = LValue.make(k)
          @bindings[lv] = Value.parse(v)
        else
          @variables[k] = Value.parse(v)
        end
      end
    end
  end
end
