require 'core/system/load/load'

model = ARGV[0]
target = ARGV[1]

m = Loader.load(model)
g = Loader.load("#{target}.grammar")
$stderr << "### translating to #{target}\n"
DisplayFormat.print(g, m, 80, $stdout, false)
