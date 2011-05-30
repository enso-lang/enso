
require 'test/unit'
require 'core/system/load/load'
require 'applications/EnsoSync/code/sync'
require 'tmpdir'

class SyncTest < Test::Unit::TestCase

  # test setup
  def setup
    @@domainpath = "applications/EnsoSync/test/example"
    @@domainfile = "domain.esync"

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

    @domain = Loader.load(@@domainfile)

    #setup temp dir
    @tmppath=Dir.tmpdir+"/test_sync/"
    FileUtils.cp_r(@@domainpath, @tmppath)
  end
  
  # test matching
  def test_sync
    rule = @domain.rules['Test']
    rule.s1.path = @tmppath+"t1/f"
    rule.s2.path = @tmppath+"t2/f"
    sync(rule.s1, rule.s2)

    #check that domain is properly modified
    assert(Equals.equals(rule.s1.basedir, rule.s2.basedir))

    #check that files are properly copied
    assert(File.exists?(@tmppath+"/t1/f/bbb"))
    assert(File.exists?(@tmppath+"/t2/f/eee"))
    assert(! (File.exists?(@tmppath+"/t2/f/d1/ddd")))
  end

  def teardown
    FileUtils.rm_rf(@tmppath)
  end
end
