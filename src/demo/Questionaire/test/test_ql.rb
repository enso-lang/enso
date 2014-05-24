require 'test/unit'

require 'core/system/load/load'
require 'core/diagram/code/construct'
require 'core/diagram/code/render'

class QuestionaireTest < Test::Unit::TestCase

  def test_can_construct
    data_file = "housing.ql"
    stencil_file = "ql.stencil"

    data = Load::load(data_file)
    stencil = Load::load(stencil_file)
    modelmap = {}

    #test if able to construct diagram from stencil
    diagram = Construct::eval(stencil, {data: data, modelmap: modelmap})
      #how to ensure generated diagram is correct?

    #we cannot test if diagram can be rendered because rendering is done in JS
  end

end
