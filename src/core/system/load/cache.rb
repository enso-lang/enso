
require 'core/schema/tools/dumpxml'

require 'rexml/document'
require 'digest/sha1'

module CacheXML
  include REXML
  
  def self.from_xml(name, input=find_xml(name))
    type = name.split('.')[-1]
    doc = Document.new(File.read(input))
    doc1 = Document.new
    doc1 << doc.root.elements.to_a[-1] 
    res = FromXML::load(Loader.load("#{type}.schema"), doc1)
    res.factory.file_path = doc.root.attributes['source']
    res
  end

  def self.to_xml(name, model=Loader.load(name), out=find_xml(name))
    res = add_metadata(ToXML::to_xml(model), name)
    pp = REXML::Formatters::Pretty.new
    File.open(out, 'w+') {|f| pp.write(res, f)}
  end

  def self.check_dep(name)
    begin
      doc = Document.new(File.read(find_xml(name)))
      #check that the source file has not changed
      #check that none of the dependencies have changed
      return false unless check_file(doc.root)
      doc.root.elements['depends'].elements.each {|e| return false unless check_file(e)}
      true
    rescue
      false
    end
  end
  
  def self.clean_cache(name=nil)
    if name.nil?  #clean everything
      File.delete("#{cache_path}*")
    else
      File.delete(find_xml(name))
    end
  end
  
  private

  def self.cache_path; "core/system/load/cache/"; end
  
  def self.find_xml(name)
    if ['schema.schema', 'schema.grammar', 'grammar.schema', 'grammar.grammar'].include? name
      "core/system/boot/#{name.gsub('.','_')}.xml"
    else
      "#{cache_path}#{name.gsub('.','_')}.xml"
    end
  end
  
  def self.check_file(element)
    path = element.attributes['source']
    checksum = element.attributes['checksum']
    begin
      readHash(path)==checksum
    rescue
      false
    end
  end
  
  def self.get_meta(name)
    e = Element.new(name)
    Loader.find_model(name) do |path|
      e.attributes['source'] = path
      e.attributes['date'] = File.ctime(path)
      e.attributes['checksum'] = readHash(path)
    end
    e
  end
  
  def self.add_metadata(orig, name=nil)
    doc = Document.new
    if name==nil
      e = Element.new('MetaData')
    else
      e = get_meta(name)
      deps = Element.new('depends')

      #analyze vertical dep
      type = name.split('.')[-1]
      deps << get_meta("#{type}.schema")
      deps << get_meta("#{type}.grammar")

      #analyze horizontal dep
      #something to do with imports, but currently nothing
      Loader.find_model(name) do |path|
        header = File.open(path, &:readline)
        if header =~ /#ruby/
          str = File.read(path)
          a = str.split("\"").map{|x|x.split("\'")}.flatten
          fnames = a.values_at(* a.each_index.select {|i| i.odd?})
          fnames.each {|fn| deps << get_meta(fn)}
        end
      end
      e << deps
    end
    e << orig.root
    doc << e
    doc
  end

  def self.readHash(path)
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

end

if __FILE__ == $0 then
  require 'core/system/load/load'

  if !ARGV[0] then
    $stderr << "Usage: #{$0} <model>\n"
    exit!
  end
#=begin
  tmp_path = CacheXML::find_xml(ARGV[0])
  orig = Loader.load(ARGV[0])
#  File.open(tmp_path, "w+") {|f| CacheXML::to_xml(ARGV[0], f)}
CacheXML::to_xml(ARGV[0])
#  res = File.open(tmp_path, "r") {|f| CacheXML::from_xml(ARGV[0], f)}
  res = CacheXML::from_xml(ARGV[0])
  raise "Wrong output!" unless Equals.equals(orig, res)
  $stderr << "All OK!\n"
#=end
  puts CacheXML::check_dep(ARGV[0])
end

