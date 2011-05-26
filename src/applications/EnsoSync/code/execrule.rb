=begin

Does the actual copying

=end

def recurse(path, factory)
  delim = "/"
  #strip ending "/"
  path = path[0..path.length-2] if path.end_with?(delim)
  fname = path[path.rindex(delim)+1..path.length-1]
  if File::directory?(path)
    d = factory["Dir"]
    d.name = fname
    Dir.foreach(path) do |entry|
      next if entry == "." || entry == ".."
      d.nodes << recurse(path+delim+entry, factory)
    end
    return d
  else
    f = factory["File"]
    f.name = fname
    return f
  end
end

# applies the patch from source to target path
def apply(base, ref, delta)
  changetype = DeltaTransform.getChangeType(delta)
  if changetype == DeltaTransform.insert
    deleteFile(base) if fileExists?(base)
    copyFile(ref, base)
  elsif changetype == DeltaTransform.delete
    deleteFile(base)
  elsif changetype == DeltaTransform.modify
    type = DeltaTransform.getObjectName(delta)
    if type == "Dir"
      #only directories will have modify_ as file must either be matched or unmatched
      delta.nodes.each do |f|
        name = f.pos
        apply(base+"/"+name, ref+"/"+f.pos, f)
      end
    elsif type == "File"
      #files with modify are treated as inserts
      deleteFile(base) if fileExists?(base)
      copyFile(ref, base)
    end
  end
end

def copyFile(srcpath, tgtpath)
  puts "copy "+srcpath+" to "+tgtpath
end

def deleteFile(path)
  puts "delete "+path
end

def mergeFile(srcpath, tgtpath)
  puts "merge "+srcpath+" and "+tgtpath
end

def fileExists?(path)
  return File.exists?(path)
end
