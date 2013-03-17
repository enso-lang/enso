
require 'core/schema/code/factory'
require 'core/system/library/schema'

module SharingFactory
  def self.new(schema, shares)
    SharingSchemaFactory.new(schema, shares)
  end

  class SharingSchemaFactory < Factory::SchemaFactory
    include Factory
    
    def initialize(schema, shares)
      super(schema)
      @shares = shares
      @memo = {}
    end

    def _objects_for(klass)
      @memo.values.select do |x|
        Schema::subclass?(x.schema_class, klass)
      end
    end

    def __install_methods(schema)
      schema.classes.each do |klass|
        define_singleton_method(klass.name) do |*args|
          #puts "FACT: #{klass.name} (sh=#{@shares.include?(klass)}) #memo=#{@memo.length}"
          if @shares.include?(klass) then
            if @memo.has_key?(args) then
              @memo[args]
            else
              @memo[args] = MObject.new(klass, self, *args)
            end
          else
            MObject.new(klass, self, *args)
          end
        end 
      end
    end

  end
  
end

if __FILE__ == $0 then
  require 'core/system/load/load'
  gll = Load::load('gll.schema')

  shares = [gll.classes["Base"],
            gll.classes["Item"],
            gll.classes["GSS"]]

  f = SharingFactory::new(gll, shares)

  p = f.Lit("keyword")
  l = f.Location("/", 0, 1, 2, 3, 4, 5)

  b1 = f.Leaf(0, 1, p, l, "a", " ")
  b2 = f.Leaf(0, 1, p, l, "a", " ")
  puts "b1: #{b1}"
  puts "b2: #{b2}"

  i1 = f.Item(p, [], 0)
  i2 = f.Item(p, [], 0)
  puts "i1: #{i1}"
  puts "i2: #{i2}"
    
    
  g1 = f.GSS(i1, 0)
  g2 = f.GSS(i2, 0)
  puts "g1: #{g1}"
  puts "g2: #{g2}"
end
