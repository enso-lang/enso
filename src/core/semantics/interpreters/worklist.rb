require 'core/semantics/code/interpreter'

module WorkList
  def initialize(initial=nil)
    @worklist = []
    @worklist = @worklist + initial unless initial.nil?
  end

  def method_missing(method_sym, obj=nil, arguments=nil, &block)
    @worklist << obj unless obj.nil? or @worklist.include?(obj)
    if !@working
      @working = true
      while !@worklist.empty?
        super(method_sym, @worklist.pop, arguments, &block)
      end
      @working = false
    end
  end
end
