require 'core/system/load/load'
require 'core/schema/tools/print'


module Parse2
  module ParseGrammar
    include Eval::EvalExpr
    include Interpreter::Dispatcher

    def parse(obj)
      dispatch_obj(:parse, obj)
    end

    def parse_Grammar(obj)
      #tokenize first
      input = @D[:input].gsub("{"," { ").gsub("}"," } ").gsub("(", " ( ").gsub(")"," ) ").gsub("|"," | ")
      #call start rule
      start_rule = obj.start
      result = nil
      dynamic_bind tokens: input.split(' ') do
        result = parse(start_rule)
      end
      if result and result[1].empty?
        result[0]
      else
        puts "parse error"
        nil
      end
    end

    def parse_Rule(obj)
      parse(obj.arg)
    end

    def parse_Alt(obj)
      found = nil
      obj.alts.each do |alt|
        if not found
          found = parse(alt)
        end
      end
      found
    end

    def parse_Sequence(obj)
      remaining_tokens = @D[:tokens]
      result = nil
      obj.elements.each do |arg|
        res = nil
        dynamic_bind tokens: remaining_tokens do
          res = parse(arg)
        end
          if res.nil?
            result = nil
            break
          end
          result |= res[0]
          remaining_tokens = res[1]
      end
        if result
          [result, remaining_tokens]
        else
          nil
        end
    end

    def parse_Create(obj)
      new = @D[:factory][obj.name]
      result = nil
      dynamic_bind curr_obj: new do
        result = parse(obj.arg)
      end
      if not result.nil?
        [new, result[1]]
      else
        nil
      end
    end

    def parse_Lit(obj)
      if @D[:tokens][0] == obj.value
        [nil, @D[:tokens][1..-1]]
      else
        nil
      end
    end

    def parse_Field(obj)
      result = parse(obj.arg)
      if result
        curr_obj = @D[:curr_obj]
        curr_obj[obj.name] = result[0]
        result
      else
        nil
      end
    end

    def parse_Regular(obj)
    end

    def parse_Call(obj)
      parse(obj.rule)
    end

    def parse_Break(obj)
    end

    def parse_Value(obj)
      if obj.kind == 'sym'
        #consume any token that starts with alpha
        next_token = @D[:tokens][0]
        if Character.isLetter(next_token[0])
          [next_token, @D[:tokens][1..-1]]
        end
      elsif obj.kind == 'int'
      end
    end
  end

  class ParseGrammarC
    include ParseGrammar
  end

  def self.parse(obj, input, factory)
    interp = ParseGrammarC.new
    interp.dynamic_bind input: input, factory: factory do
      interp.parse(obj)
    end
  end
end



