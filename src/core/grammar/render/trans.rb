require 'core/system/load/load'

model = ARGV[0]
target = ARGV[1]
if ARGV.size > 2
  out = File.new(ARGV[2], "w")
else
  out = $stdout
end
m = Loader.load(model)
g = Loader.load("#{target}.grammar")
$stderr << "### translating to #{target}\n"
DisplayFormat.print(g, m, 80, out, false)
