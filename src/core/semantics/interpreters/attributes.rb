require 'core/semantics/code/combinators'

module AttrGrammar
  extend Traverse
  
  attr_accessor :clean, :onstack

  def traverse_?(type, fields, args)

    return @memo if @clean

    @memo = @memo || default(@this)
    @clean = true

    deps = @@dependencies
    fields.each do |k,v|
      f= type.all_fields[k]
      if !f.many
        if f.type.Primitive?
        else
          deps[v] = [] unless deps[v]
          deps[v] << self unless deps[v].include? self
        end
      else
        v.values.each do |vv|
          deps[vv] = [] unless deps[vv]
          deps[vv] << self unless deps[vv].include? self
        end
      end
    end

    old = @memo
    @onstack = true
    @memo = yield
    @onstack = false
    
    if @memo!=old
      @@dependencies[self] ||= []
      @@dependencies[self].each {|dep| dep.clean=false unless dep.onstack; append(dep)}
    end

    @clean = true
    @memo
  end

  def __init; super; @@dependencies={}; end
end
