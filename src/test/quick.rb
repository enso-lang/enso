
Dir['core/**/*.rb'].each do |t| 
 begin
  puts "="*80
  puts "#{'-'*20} #{t} #{'-'*20}"
  system "arch -i386 ruby #{t} 2>&1"
 rescue
 end
end
=begin
require 'core/system/load/load'
require 'core/system/boot/grammar_schema'

  require 'core/grammar/code/layout'
  
  schema_grammar = Loader.load('schema.grammar')
  grammar_schema = Loader.load('grammar.schema')
  
  DisplayFormat.print(schema_grammar, GrammarSchema.schema)
  DisplayFormat.print(schema_grammar, grammar_schema)
=end