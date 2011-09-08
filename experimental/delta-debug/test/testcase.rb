require '../experimental/delta-debug/test/drawme.rb'

# simple test case to ensure that the point (5,5) is not painted
# used by test_dd

def testcase(canvas)
  res = Draw.drawme(canvas)
  raise if res[5][5] == 1
end
