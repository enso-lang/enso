bin/render.sh test.genealogy genealogy-dot > apps/genealogy/test/test.dot
dot -Tpdf apps/genealogy/test/test.dot -o apps/genealogy/test/test.pdf
open apps/genealogy/test/test.pdf