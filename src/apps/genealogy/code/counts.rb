require 'core/system/load/load'

def count_genealogy(g)

	puts "NUMBER OF PEOPLE: #{g.people.count}"
	for p in g.people
	  puts "  #{p.name}"
	end


end

if __FILE__ == $0
  g = Load::load(ARGV[0])
  count_genealogy(g)
end
