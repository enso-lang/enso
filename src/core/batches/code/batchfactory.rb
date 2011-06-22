=begin

Note that unlike SecureFacotry, BatchFactory has nothing to do with the original factory class

=end

require 'core/schema/code/factory'

class BatchFactory

  def initialize(schema, queryobj, db)
    @schema = schema
    @factory = Factory.new(schema)
    #init db here
    #pass query object to db and get back a resultset
    #resultset = db.blablabla
    @root = populate_with_db(@factory, resultset)
  end

  #return a checked object corresponding to the root of the query
  def get_root()
    @root
  end

  #turn this resultset into a bunch of checked objects
  def populate_with_db(factory, resultset)
  end

end
