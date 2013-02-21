require 'enso'
require 'core/system/load/load'
require 'core/grammar/render/layout'

if !ARGV[0] then
  $stderr << "Usage: render.rb <model> [grammar] -o <output>"
  exit!(1)
end
name = ARGV[0]
if ARGV.size > 1
  if ARGV[1] == "-o"
    outname = ARGV[1]
  else
    outgrammar = ARGV[1]
    if ARGV[2] == "-o"
      outname = ARGV[3]
    end
  end
end

if !outgrammar
  filename = name.split("/")[-1]
  outgrammar = filename.split(".")[-1]
end
if outname
  out = File.new(outname, "w")
else
  out = $stdout
end

m = Load::load(name)
g = Load::load("#{outgrammar}.grammar")
$stderr << "## Printing #{ARGV[0]}...\n"
Layout::DisplayFormat.print(g, m, out, false)
