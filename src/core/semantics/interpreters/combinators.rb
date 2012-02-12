=begin
The combinators Sequence, Alternative (Fork) and Traversal were previously described in
  Visser, J., Visitor Combination and Traversal Control, OOPSLA 2001
=end

# do A then B
def Sequence(mods_map)
  Compose('Sequence', mods_map) do |obj, args={}|
    mods_map.keys.each do |op|
      send(op, obj, args)
    end
  end
end

# do A then pass the results as a tail call to B (continuation)
def Continue(mods_map)
end

# do A which is traversal control for B
def Traversal(mods_map)

end

# do A and B at the same time
# semantically identical to Sequence, except that programmer
#guarantees A and B do not interfere
def Fork(mods_map)
  Compose('Sequence', mods_map) do |obj, args={}|
    mods_map.keys.each do |op|
      send(op, obj, args)
    end
  end
end

