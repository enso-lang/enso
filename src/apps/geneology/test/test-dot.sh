bin/render.sh test.genealogy genealogy-dot > apps/geneology/test/test.dot
dot -Tpdf apps/geneology/test/test.dot -o apps/geneology/test/test.pdf
open apps/geneology/test/test.pdf