
require 'rexml/document'

# todo: move to schema/tools

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
      next if f == back_link
      next if !this[f.name]
      if f.type.Primitive? then
        e.attributes[f.name] = this[f.name].to_s
      else 
        ef = Element.new(f.name)
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

  exit! if ARGV[0] != 'boot'

  pp = REXML::Formatters::Pretty.new

  ss = Loader.load('schema.schema')
  File.open('core/system/boot/schema_schema.xml', 'w') do |f|
    x = ToXML::to_doc(ss)
    pp.write(x, f)
  end

  gs = Loader.load('grammar.schema')
  File.open('core/system/boot/grammar_schema.xml', 'w') do |f|
    x = ToXML::to_doc(gs)
    pp.write(x, f)
  end

  is = Loader.load('instance.schema')
  File.open('core/system/boot/instance_schema.xml', 'w') do |f|
    x = ToXML::to_doc(is)
    pp.write(x, f)
  end


  gg = Loader.load('grammar.grammar')
  File.open('core/system/boot/grammar_grammar.xml', 'w') do |f|
    x = ToXML::to_doc(gg)
    pp.write(x, f)
  end
end
