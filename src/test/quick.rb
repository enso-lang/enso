
Dir['core/**/*.rb'].each do |t| 
 #begin
  puts "="*80
  puts "#{'-'*20} #{t} #{'-'*20}"
  system "ruby -I. #{t} 2>&1"
 #rescue
 #end
end
