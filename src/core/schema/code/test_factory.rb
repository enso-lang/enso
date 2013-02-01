
if __FILE__ == $0 then
  require 'core/system/load/load'
  require 'core/schema/tools/print'
  M = ManagedData
  ss = Loader.load('schema.schema')
  fact = M::Factory.new(ss)
  puts "Schema"
  s = fact.Schema
  puts "CLass FOO"
  c = fact.Class('Foo')
  puts "c.schema = s"
  c.schema = s

  puts "Primitiv str"
  p = fact.Primitive('str')

  puts "p.schema = s"
  p.schema = s

  puts "field 'bla' c = owner, p is type"
  f = fact.Field('bla', c, p, true, false, false)

  puts "f.type = p"

  f.type = p
  puts f.name
  # c.defined_fields << f
  s = s.finalize
  puts c
  puts c.name
  c.fields.each do |fld|
    puts "FLD: #{fld}"
    puts "OWNER: #{fld.owner}"
    puts "TYPE: #{fld.type}"
  end
  Print.print(s)

  ss.classes.each do |cls|
    puts cls._origin
    puts "PATH = #{cls._path}"
    cls.fields.each do |fld|
      puts "\tFIELD PATH = #{fld._path}"
      ss.classes['Field'].fields.each do |f|
        org = fld._origin_of(f.name)
        path = fld._path_of(f.name)
        puts "\t#{f.name}: #{org}" if org
        puts "\t#{f.name}: #{path}"
      end
    end
 end
end
