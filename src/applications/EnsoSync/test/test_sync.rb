
require 'test/unit'
require 'core/system/load/load'
require 'applications/EnsoSync/code/sync'
require 'tmpdir'

class SyncTest < Test::Unit::TestCase

  # test setup
  def setup
    @tmppath = "/tmp/root"
    system("applications/EnsoSync/scripts/test-setup.sh #{@tmppath}")

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
  end
  
  # test matching
  def test_sync
    ts = Thread.start {
      system("applications/EnsoSync/scripts/test-host.sh #{@tmppath}")
    }
    sleep(10)
    tc = Thread.start {
      system("applications/EnsoSync/scripts/test-client.sh #{@tmppath}")
    }
    sleep(20)

    #check that files are properly copied
    begin
    assert(File.exists?(@tmppath+"/client/f/bbb"))
    assert(File.exists?(@tmppath+"/server/f/eee"))
    assert(! (File.exists?(@tmppath+"/server/f/d1/ddd")))
    
    #kill threads
    ensure
    system("killall -9 ruby")
    end
  end

  def teardown
    FileUtils.rm_rf(@tmppath)
  end
end
