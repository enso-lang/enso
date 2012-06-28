
require 'rexml/document'

module ToXML
  include REXML

  def self.to_doc(this)
    doc = Document.new
    doc << to_xml(this)
  end

  def self.to_xml(this, back_link = nil)
    return nil if this.nil?
    e = Element.new(this.schema_class.name)
    this.schema_class.fields.each do |f|
      next if f.computed
      next if !this[f.name]
      if f.type.Primitive? then
        e.attributes[f.name] = this[f.name].to_s
      else 
        ef = Element.new(f.name)
        ef.attributes['many'] = f.many
        ef.attributes['keyed'] = IsKeyed?(f.type)
        if f.many then
          next if this[f.name].empty?
          if f.traversal then
            this[f.name].each do |fobj|
              ef << to_xml(fobj, f.inverse)
            end
          else
            ef.text = this[f.name].map do |elt|
              elt._path
            end.join(' ')
          end
        else
          if f.traversal then
            ef << to_xml(this[f.name], f.inverse)
          else
            ef.text = this[f.name]._path.to_s
          end
        end
        e << ef
      end
    end
    return e
  end
end

if __FILE__ == $0 then
  require 'core/system/load/load'

  if !ARGV[0] then
    $stderr << "Usage: #{$0} <model>\n"
    exit!
  end

  mod = Loader.load(ARGV[0])
  pp = REXML::Formatters::Pretty.new
  pp.write(ToXML::to_doc(mod), $stdout)
end
