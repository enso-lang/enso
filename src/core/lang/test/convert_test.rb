import 'core/lang/code/convert.rb' 
 
  name = ARGV[0]
  outname = ARGV[1]
  grammar = ARGV[2] || "code"
  
  #pp Ripper::SexpBuilder.new(File.new(name, "r")).parse
  
  puts "Converting to JS: #{name}"
  m = CodeBuilder.build(File.new(name, "r"))
  g = Load::load("#{grammar}.grammar")
  # jj Dumpjson::to_json(m)
   
  out = File.new(outname, "w")
  $stdout << "## storing #{outname}\n"
  Layout::DisplayFormat.print(g, m, out, false)
