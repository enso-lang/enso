require 'core/semantics/code/combinators'

module AttrGrammar
  #this is technically *not* a map as all it does is go through the entire graph once
  #I would rather call it a 'Functor'(?), and can be used to write maps, folds, filter, etc

  extend Control
  
  operation :attr
  
  attr_accessor :clean, :onstack

  def attr_?(type, fields, args={})
    
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
  def __hidden_calls; super+[:attr]; end
end
