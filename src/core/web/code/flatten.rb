
require 'core/web/code/reference'




def parse_ref(value)
  value.split(/\./).flat_map do |x|
    if x =~ /^(.*)\[(.*)\]$/ then
      [$1, $2]
    else
      x
    end
  end
end

def to_ref(lst)
  return nil if lst.empty?
  puts "L = #{lst}"
  Ref.new(lst.first, to_ref(lst[1..-1]))
end

def to_lvalue(lst)
  LValue.new(to_ref(lst[0..-2]), lst[-1])
end


def flatten(hash)
  tbl = {}
  hash.each do |k, v|
    if v.is_a?(Hash) then
      flatten(v).each do |k2, v2|
        tbl[k + k2] = v2
      end
    else
      tbl[k] = v
    end
  end
  return tbl
end



hash = {
  '.a' => {'[0]' => {".x" => '1'}},
  '.b' => {'[1]' => {".x" => '2'}}
}

parse(flatten(hash)).each do |k, v|
  p k
  p v
end

p parse_ref('a.b[3].c[abc].s')
