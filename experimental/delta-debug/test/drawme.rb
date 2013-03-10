=begin
Simple interpreter that renders geometry drawings as 2D bit arrays.
Used by test_dd
=end

require 'core/system/load/load'
require 'core/schema/tools/print'
require 'core/grammar/code/layout'

class Draw

  def self.plot(x, y, res)
    return res if x<0||y<0
    if y>=res.size
      for i in res.size..y
        res << []
      end
    end
    row = res[y]
    if x>=row.size
      for i in row.size..x
        row << 0
      end
    end
    row[x] = 1
    res
  end

  def self.draw_Drawing(d, res)
    d.shapes.inject(res) do |r, s|
      draw(s, r)
    end
  end

  def self.draw_Point(d, res)
    plot(d.x, d.y, res)
  end

  def self.draw_Line(d, res)
    for i in (0..d.pts.size-2)
      p1 = d.pts[i]; p2 = d.pts[i+1]
      segment(p1, p2, res)
    end
    res
  end

  def self.segment(p1, p2, res)
    angle = (p2.y-p1.y).to_f / (p2.x-p1.x).to_f
    for i in p1.x..p2.x
      j=(i-p1.x)*angle +p1.y
      j1 = j.floor
      plot(i,j,res)
      if j1!=j
        #plot(i-1,j, res)
      end
    end
    res
  end

  def self.draw(obj, *args)
    send("draw_"+obj.schema_class.name, obj, *args)
  end

  def self.drawme(canvas)
    init = [[0]]
    res = canvas.drawings.inject(init) do |res, d|
      draw(d, res)
    end
    res
  end

  def self.render(res)
    for i in (0..res.size-1).to_a.reverse
      row = res[i]
      for j in 0..row.size-1
        if row[j] == 1
          print "x"
        else
          print " "
        end
      end
      print "\n"
    end
    print "\n"
  end
end


