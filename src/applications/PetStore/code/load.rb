

require 'sequel'

require 'core/system/load/load'
require 'core/schema/tools/print'

def load_petstore(file = 'applications/petstore/data/petstore.db')
  db = Sequel.sqlite(file)

  ps = Loader.load('petstore.schema')
  fact = Factory.new(ps)

  cats = {}
  db[:Category].all.each do |h|
    id = h[:categoryid]
    cats[id] = fact.Category(id, h[:name], h[:description], h[:imageurl])
  end

  #puts "CATEGORIES"
  #p cats

  prods = {}
  db[:Product].all.each do |h|
    id = h[:productid]
    prods[id] = fact.Product(id, h[:name], h[:description], 
                             h[:imageurl])
    cats[h[:categoryid]].products << prods[id]
  end

  #puts "PRODUCTS"
  #p prods

  adds = {}
  db[:Address].all.each do |h|
    id = h[:addressid]
    adds[id] = fact.Address(id, h[:street1], h[:street2],
                            h[:city], h[:state], h[:zip],
                            h[:latitude], h[:longitude])
  end

  #puts "ADDRESSES"
  #p adds

  cis = {}
  db[:SellerContactInfo].all.each do |h|
    id = h[:contactinfoid]
    cis[id] = fact.SellerContactInfo(id, h[:lastname], h[:firstname],
                                     h[:email])
  end

  #puts "CONTACTINFOS"
  #p cis


  items = {}
  db[:Item].all.each do |h|
    id = h[:itemid]
    items[id] = fact.Item(id, prods[h[:productid]],
                          h[:name], h[:description],
                          h[:imageurl], h[:imagethumburl],
                          (h[:price] * 100.0).to_i,
                          adds[h[:address_addressid]],
                          cis[h[:contactinfo_contactinfoid]]
                          )
    items[id].totalScore = h[:totalscore]
    items[id].numberOfVotes = h[:numberofvotes]
    items[id].disabled = h[:disabled]
  end

  #puts "ITEMS"
  #p items

  tags = {}
  db[:Tag].all.each do |h|
    id = h[:tagid]
    tags[id] = fact.Tag(id, h[:tag], h[:refcount])
  end

  #puts "TAGS"
  #p tags

  db[:tag_item].all.each do |h|
    tags[h[:tagid]].items << items[h[:itemid]]
  end


  catalog = fact.Catalog
  cats.each_value do |c|
    catalog.categories << c
  end

  prods.each_value do |p|
    catalog.products << p
  end

  items.each_value do |i|
    catalog.items << i
  end

  cis.each_value do |c|
    catalog.sellers << c
  end

  adds.each_value do |a|
    catalog.addresses << a
  end

  tags.each_value do |t|
    catalog.tags << t
  end

  return catalog
end

if __FILE__ == $0 then
  catalog = load_petstore
  Print.print(catalog)
end
