require 'core/expr/code/env'
require 'core/expr/code/eval'
require 'core/schema/code/factory'
require 'core/system/load/load'

#TODO: Rewrite this using SimpleDelegate

module Proxy
  class Proxy
    attr_reader :_val
    attr_accessor :_sources, :_tree
      #sources is a env: name->(file, path) that says where this line came from
      #deptree is an expression tree whose leaf nodes are vars in [sources]
    @@factory = nil
    def self.new(*args)
      if args[0].is_a? TrueClass or args[0].is_a? FalseClass  #TODO: use delegates so that bools work
        args[0]
      else
        super(*args)
      end
    end
    def initialize(val, file=nil, path=nil)
      if @@factory.nil?
        @@factory = Factory::SchemaFactory.new(Load::load("expr.schema"))
      end
      if val.is_a? Proxy
        @_val = val._val
        @_sources = val._sources
        @_tree = val._tree
      else
        @_val = val
        raise "Improper init of proxy sources" if file.nil? != path.nil?
        if file.nil?
          @_sources = {}
          @_tree = Eval.make_const(@@factory, val)
        else
          id = [file,path.to_s].hash % 100000
          @_tree = @@factory.EVar
          @_tree.name = "@#{id}"
          @_sources = {@_tree.name=>[file,path]}
        end
      end
    end
    def ops
      [:==, :+, :-, :*, :/, :>, :<, :>=, :<=, :-@]
    end
    def op2str(op)
      if op==(:==)
        "eql?"
      else
        op.to_s
      end
    end
    def method_missing(sym, *args, &block)
      if @_val.is_a? Factory::MObject #object
        if f = @_val.schema_class.all_fields[sym.to_s]
          if !f.many
            Proxy.new(@_val.send(sym), @_val.factory.file_path[0], @_val._path.field(sym.to_s))
          else
            if f.type.key
              newlist = {}
              @_val[f.name].each_pair do |k,v|
                newlist[k] = Proxy.new(v)
              end
              newlist
            else
              newlist = []
              @_val[f.name].each do |v|
                newlist << Proxy.new(v)
              end
              newlist
            end
          end
        else
          @_val.send(sym, *args, &block)
        end
      else
        if sym==:coerce
          [Proxy.new(args[0]), self]
        elsif ops.include? sym
          res = nil
          if args.empty?
            res = Proxy.new(@_val.send(sym, *args, &block))
            if res.is_a? Proxy #TODO: non-proxies only come from bools (see init)
              res._sources = @_sources
              res._tree = @@factory.EUnOp(op2str(sym), @_tree)
            end
          else
            other = Proxy.new(args[0])
            res = Proxy.new(@_val.send(sym, other._val, &block))
            if res.is_a? Proxy #TODO: non-proxies only come from bools (see init)
              if other.is_a? Proxy
                res._sources = @_sources.merge(other._sources)
                res._tree = @@factory.EBinOp(op2str(sym), @_tree, other._tree)
              else
                res._sources = @_sources
                res._tree = @@factory.EBinOp(op2str(sym), @_tree, Eval.make_const(@@factory, res))
              end
            end
          end
          res
        else
          @_val.send(sym, *args, &block)
        end
      end
    end
    def ==(other)
      method_missing(:==, other)
    end
    def ===(other)
      method_missing(:===, other)
    end
    def hash
      method_missing(:hash)
    end
    def valueOf; @_val.valueOf end #[JS HACK] used for JS equality
    def to_s; "#{@_val}" end
    def eql?(other); @_val.eql?(other) end
    def hash; @_val.hash end
  end

  def proxify(obj)
    obj.fields.each do |f|
      if f.traversal
        if f.type.Primitive?
          obj[f.name] = Proxy.new(obj[f.name])
        elsif !f.many
          
        else
        end
      end
    end
  end

end
