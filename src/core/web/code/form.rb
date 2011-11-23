
require 'core/web/code/web'
require 'core/web/code/result'

module Web::Eval
  class Form
    attr_reader :actions, :env

    def initialize(data, env, root)
      @bindings = {}
      @actions = []
      @env = {}
      parse(flatten(data), env, root)
      puts "________: #{to_s}"
    end

    def each_binding(&block)
      @bindings.each(&block)
    end

    def each_action(&block)
      @actions.each(&block)
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
      @env.each do |k, v|
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
        elsif v.is_a?(Array)
          ## TODO!!!
          raise "NOT YET IMPLEMENTED: collections in forms"
        else
          tbl[k] = v
        end
      end
      return tbl
    end

    def parse(hash, env, root)
      hash.each do |k, v|
        if k =~ /^!/ then 
          @actions << Action.parse(k, v, root, env)
        elsif k =~ /^[@.]/ then
          @bindings[Ref.parse(k, root, env)] = Result.parse(v, root, env)
        else
          @env[k] = Result.parse(v, root, env)
        end
      end
    end
  end
end
