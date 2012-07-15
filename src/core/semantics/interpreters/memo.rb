require 'core/semantics/code/combinators'

module Memo

  extend Wrap
  
  operation :memo

  def memo_?(type, fields, args={})
    if @memo
      @memo
    else
      @memo = yield
    end
  end

  def initialize(*args)
    super; @memo = nil;
  end
  def __hidden_calls; super+[:memo]; end
end
