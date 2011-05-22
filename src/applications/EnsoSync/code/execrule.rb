=begin

Does the actual copying from

=end

#require 'ftools'

# applies the patch from source to target path
def apply(src, tgt, delta)
  changetype = DeltaTransform.getChangeType(delta)
  if changetype == DeltaTransform.insert
    copyFile(src, tgt)
  elsif changetype == DeltaTransform.delete
    deleteFile(tgt)
  elsif changetype == DeltaTransform.modify
    #only directories will have modify_ as file must either be matched or unmatched
    delta.nodes.each do |f|
      name = f.pos
      apply(src+"/"+name, tgt+"/"+f.pos, f)
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
