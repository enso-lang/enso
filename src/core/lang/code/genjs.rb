require 'core/system/load/load'


if __FILE__ == $0 then
  name = ARGV[0]
  m = Loader.load(name)
  g = Loader.load("code_js.grammar")
  
  out = File.new("#{name.chomp(".code")}.js", "w")
  DisplayFormat.print(g, m, 80, out)
  
end
