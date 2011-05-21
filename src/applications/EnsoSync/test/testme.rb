require 'core/system/load/load'
require 'core/schema/tools/print'
require 'core/grammar/code/layout'
require 'core/diff/code/delta'
require 'core/diff/code/diff'
require 'core/diff/code/patch'
require 'core/system/library/schema'

schema = Loader.load('esync.schema')
grammar = Loader.load('esync.grammar')

# search the tree to fill in the nodes
factory = Factory.new(schema)

def recurse(path, factory)
  delim = "/"
  #strip ending "/"
  path = path[0..path.length-2] if path.end_with?(delim)
  fname = path[path.rindex(delim)+1..path.length-1]
  if File::directory?(path)
    d = factory["Dir"]
    d.name = fname
    Dir.foreach(path) do |entry|
      next if entry == "." || entry == ".."
      d.nodes << recurse(path+delim+entry, factory)
    end
    return d
  else
    f = factory["File"]
    f.name = fname
    return f
  end
end

d = factory.Domain
s1 = factory.Source("s1")
#s1.rootpath = "/home/alexloh/workspace/enso"
s1.rootpath = "/home/alexloh/temp/t1/f"
s1.rootdir = recurse(s1.rootpath, factory)
#d.sources << s1
s2 = factory.Source("s1")
#s2.rootpath = "/home/alexloh/workspace/enso2"
s2.rootpath = "/home/alexloh/temp/t2/f"
s2.rootdir = recurse(s2.rootpath, factory)
#d.sources << s2

Print.print(s1)
Print.print(s2)

res = diff(s1, s2)
puts "ASDF"
Print.print(res)
