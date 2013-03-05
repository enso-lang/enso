=begin

Performs all file I/O required by EnsoSync.
The rest of EnsoSync should only deal with models

=end

require 'digest/sha1'
require 'fileutils'

PATH_DELIM = "/"

def read_from_fs(root, path, factory)
  delim = PATH_DELIM
  #strip ending PATH_DELIM
  mypath = "#{root}#{delim}#{path}"
  mypath = mypath[0..mypath.size-2] if mypath.end_with?(delim)
  fname = path.include?(delim) ? path[path.rindex(delim)+1..path.size-1] : path
  if File::directory?(mypath)
    d = factory["Dir"]
    d.name = fname
    d.isdir = true
    Dir.foreach(mypath) do |entry|
      next if entry == "." || entry == ".."
      d.nodes << read_from_fs(root, path+delim+entry, factory)
    end
    return d
  else
    f = factory["File"]
    f.name = fname
    f.isdir = false
    f.checksum = readHash(mypath)
    return f
  end
end

# applies the patch from source to target path
def apply_to_fs(root, base, ref, delta)
  changetype = DeltaTransform.getChangeType(delta)
  if changetype == DeltaTransform.insert
    deleteFile(base) if fileExists?(base) and DeltaTransform.getObjectName(delta)=="Dir" 
    copyFile(ref, base)
  elsif changetype == DeltaTransform.delete
    deleteFile(base)
  elsif changetype == DeltaTransform.modify
    type = DeltaTransform.getObjectName(delta)
    if type == "Dir"
      #only directories will have modify_ as file must either be matched or unmatched
      delta.nodes.each do |f|
        name = f.pos
        apply_to_fs(root, base+PATH_DELIM+name, ref+PATH_DELIM+f.pos, f)
      end
    elsif type == "File"
      #files with modify are treated as inserts
      copyFile(ref, base)
    end
  end
end

def copyFile(srcpath, tgtpath)
#  puts "copy "+srcpath+" to "+tgtpath
  FileUtils.cp_r(srcpath, tgtpath)
end

def deleteFile(path)
#  puts "delete "+path
  FileUtils.rm_rf(path)
end

def mergeFile(srcpath, tgtpath)
  puts "merge "+srcpath+" and "+tgtpath
end

def writeFile(path, contents, overwrite=true)
  File.open(path, 'w') {|f| f.write(contents)}
end

def createDir(path)
  FileUtils.mkdir_p(path)
end

def deleteDir(path)
  FileUtils.rm_rf(path)
end

def fileExists?(path)
  File.exists?(path)
end

def readHash(path)
  hashfun = Digest::SHA1.new
  fullfilename = path
  open(fullfilename, "r") do |io|
    while (!io.eof)
      readBuf = io.readpartial(50)
      hashfun.update(readBuf)
    end
  end
  return hashfun.to_s
end
