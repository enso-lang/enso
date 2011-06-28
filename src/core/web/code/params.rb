
require 'core/web/code/reference'

module Web::Eval
  class Params
    attr_reader :actions

    def initialize(data)
      @updates = {}
      @actions = []
      parse(flatten(data))
    end

    def as_env
      env = {}
      @updates.each do |k, v|
        env[k] = v if k.var?
      end
    end

    def binds?(ref)
      @upates[ref]
    end

    def each(&block)
      @updates.each(&block)
    end

    def to_s
      s = "UPDATES:\n"
      @updates.each do |k, v|
        s << "\t#{k}:\t#{v}\n"
      end
      s << "ACTIONS:\n"
      @actions.each do |k, v|
        s << "\t#{k}:\t#{v}\n"
      end      
    end

    private

    def flattened(hash)
      hash.each do |k, v|
        if v.is_a?(Hash) then
          flattened(v) do |path, v|
            yield [k, *path], v
          end
        else
          yield [k], v
        end
      end
    end

    def flatten(hash)
      tbl = {}
      hash.each do |k, v|
        if v.is_a?(Hash) then
          flatten(v).each do |k2, v2|
            tbl[k + k2] = v2
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
        else
          lv = LValue.make(k)
          if v =~ /^[@.]/ then
            @updates[lv] = Ref.make(v)
          elsif v.is_a?(Array) then
            @updates[lv] = v.map { |x| Ref.make(x) }
          else
            @updates[lv] = Value.new(v)
          end
        end
      end
    end
  end
end
