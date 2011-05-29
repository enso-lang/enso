
require 'tmpdir'

class SyncTest < Test::Unit::TestCase

  # test setup
  def setup
    @basepath = '/tmp/esync'
=begin
    create the following file structure (paths ending with / are dirs):
    base:
      f/aaa
    t1:
      f/aaa
      f/ccc
      f/d1/
      f/eee
    t2:
      f/aaa
      f/bbb
      f/ccc
      f/d1/
      f/d1/ddd
=end
    Dir.mkdir(@basepath)
    Dir.mkdir(@basepath+"/base/")
    Dir.mkdir(@basepath+"/base/f")
    File.new( @basepath+"/base/f/aaa")
    Dir.mkdir(@basepath+"/t1/")
    Dir.mkdir(@basepath+"/t1/f")
    File.new( @basepath+"/t1/f/aaa")
    File.new( @basepath+"/t1/f/ccc")
    Dir.mkdir(@basepath+"/t1/f/d1")
    File.new( @basepath+"/t1/f/eee")
    Dir.mkdir(@basepath+"/t2/")
    Dir.mkdir(@basepath+"/t2/f")
    File.new( @basepath+"/t2/f/aaa")
    File.new( @basepath+"/t2/f/bbb")
    File.new( @basepath+"/t2/f/ccc")
    Dir.mkdir(@basepath+"/t2/f/d1")
    File.new( @basepath+"/t2/f/d1/ddd")
    
    @basedomain = Loader.load('base.esync')
  end
  
  # test matching
  def test_sync
    sync(path1, path2, basesource)
    #check that the files are properly updated
    assert(File.exists?(@basepath+"/t1/f/bbb"))
    assert(File.exists?(@basepath+"/t2/f/eee"))
  end

  def teardown
    Dir.delete(@basepath)
  end
end
