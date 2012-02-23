#require 'tempfile'
require 'FileUtils'

# Example 1 - Read File and close
def scan(fileName, beginpos, endpos, fileloc)
  file = File.new(fileName, "r")
  counter = 1
  while (line = file.gets)
    if line =~ /BEGIN_(\w+)/
      throw "Symbol '#{$1}' already defined" if fileloc[$1]
      fileloc[$1] = fileName
      beginpos[$1] = counter+1
      puts "BEGIN #{$1}: #{beginpos[$1]}"
    end
    if line =~ /END_(\w+)/
      endpos[$1] = counter-1
      puts "END #{$1}: #{endpos[$1]}"
    end
    counter = counter + 1
  end
  file.close
end

def process(file, out, beginpos, endpos, fileloc)
  while (line = file.gets)
    if line =~ /APPLY:(\w+)=(\w+)/
      var = $1
      label = $2
      line = line.sub( /#{var}=([0-9-]*)/, "#{var}=#{beginpos[label]}-#{endpos[label]}" )
      line = line.sub( /\{[^{]*\}/, "{#{fileloc[label]}}" )
    end
    out.write(line)
  end
  file.close
  out.close
end

fileloc = {}
beginpos = {}
endpos = {}

Dir['../src/*.java'].each do |file| 
  scan(file, beginpos, endpos, fileloc)
end
Dir['../src/*/*.java'].each do |file| 
  scan(file, beginpos, endpos, fileloc)
end

Dir['*.tex'].each do |file| 
  #temp = Tempfile.new('compute_positions')
  tempname = "footempfile.txt"
  temp = File.new(tempname, "w")
  process(File.new(file, "r"), temp, beginpos, endpos, fileloc)
  FileUtils.cp(file, "#{file}-old")
  FileUtils.cp(tempname, file)
end

