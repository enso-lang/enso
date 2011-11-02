

set title "S ::= b | S S | S S S"
set ylabel "seconds"
set xlabel "n"

set terminal png
set output 'gamma2.png'

f(x) = a*x**3 + b*x**2 + c*x + d
fit f(x) 'gamma2.dat' via a, b, c, d


plot 'gamma2.dat' using 1:2 with lines title "GLL", f(x) title "a.x^3+b.x^2+c.x+d"

set terminal x11
replot



