#!/bin/sh

#set -x
set -e

BOOTSTRAP_CODE="core/system/boot"
UTILITIES_CODE="core/system/utils"
SCHEMA_CODE="core/schema/code"
GRAMMAR_CODE="core/grammar/parse"
FORMAT_CODE="core/grammar/render"
WEB_CODE="core/web/code"
SECURITY_CODE="core/security/code"
DIAGRAM_CODE="core/diagram/code"
EXPRESSION_CODE="core/expr/code"


CLOC="cloc.pl --exclude-lang=XML"

/bin/echo "***** CORE CODE *****"
/bin/echo -n "BOOTSTRAP_CODE: "; ${CLOC} ${BOOTSTRAP_CODE} | grep -e "^SUM" | awk "{print \$5}"
/bin/echo -n "UTILITIES_CODE: "; ${CLOC} ${UTILITIES_CODE} | grep -e "^SUM" | awk "{print \$5}"
/bin/echo -n "SCHEMA_CODE: "; ${CLOC} ${SCHEMA_CODE} | grep -e "^SUM" | awk "{print \$5}"
/bin/echo -n "GRAMMAR_CODE: "; ${CLOC} ${GRAMMAR_CODE} | grep -e "^SUM" | awk "{print \$5}"
/bin/echo -n "FORMAT_CODE: "; ${CLOC} ${FORMAT_CODE} | grep -e "^SUM" | awk "{print \$5}"
/bin/echo -n "WEB_CODE: "; ${CLOC} ${WEB_CODE}  | grep -e "^SUM" | awk "{print \$5}"
/bin/echo -n "SECURITY_CODE: "; ${CLOC} ${SECURITY_CODE} | grep -e "^SUM" | awk "{print \$5}"
/bin/echo -n "DIAGRAM_CODE: "; ${CLOC} ${DIAGRAM_CODE} | grep -e "^SUM" | awk "{print \$5}"
/bin/echo -n "EXPRESSION_CODE: "; ${CLOC} ${EXPRESSION_CODE} | grep -e "^SUM" | awk "{print \$5}"
/bin/echo "========================"
/bin/echo -n "TOTAL: "; ${CLOC} ${BOOTSTRAP_CODE} ${UTILITIES_CODE} ${SCHEMA_CODE} ${GRAMMAR_CODE} ${FORMAT_CODE} ${WEB_CODE} ${SECURITY_CODE} ${DIAGRAM_CODE} ${EXPRESSION_CODE} | grep -e "^SUM" | awk "{print \$5}"
echo
echo

SCHEMA_MODELS="core/schema/models/schema.schema \
	core/schema/models/schema.grammar"
GRAMMAR_MODELS="core/grammar/models/grammar.schema \
	core/grammar/models/grammar.grammar \
	core/grammar/models/path.grammar \
	core/grammar/models/path.schema"
FORMAT_MODELS="core/grammar/models/layout.schema"
WEB_MODELS="core/web/models/content.grammar \
	core/web/models/element.grammar \
	core/web/models/element.schema \
	core/web/models/content.schema \
	core/web/models/prelude.web \
	core/web/models/web_base.grammar \
	core/web/models/web_base.schema \
	core/web/models/xml.grammar \
	core/web/models/xml.schema"
SECURITY_MODELS="core/security/models/auth.grammar \
	core/security/models/auth.schema"
DIAGRAM_MODELS="core/diagram/models/diagram.grammar \
	core/diagram/models/diagram.schema \
	core/diagram/models/stencil.grammar \
	core/diagram/models/stencil.schema"
EXPRESSION_MODELS="core/expr/models/expr.schema \
	core/expr/models/expr.grammar \
	core/expr/models/impl.schema \
	core/expr/models/impl.grammar"


/bin/echo "***** CORE MODELS *****"

/bin/echo -n "SCHEMA_MODELS:"; cat ${SCHEMA_MODELS} | grep -v -e "^[ \t]*$" | wc -l
/bin/echo -n "GRAMMAR_MODELS:"; cat ${GRAMMAR_MODELS} | grep -v -e "^[ \t]*$" | wc -l
/bin/echo -n "FORMAT_MODELS:"; cat ${FORMAT_MODELS} | grep -v -e "^[ \t]*$" | wc -l
/bin/echo -n "WEB_MODELS:"; cat ${WEB_MODELS} | grep -v -e "^[ \t]*$" | wc -l
/bin/echo -n "SECURITY_MODELS:"; cat ${SECURITY_MODELS} | grep -v -e "^[ \t]*$" | wc -l
/bin/echo -n "DIAGRAM_MODELS:"; cat ${DIAGRAM_MODELS} | grep -v -e "^[ \t]*$" | wc -l
/bin/echo -n "EXPR_MODELS:"; cat ${EXPRESSION_MODELS} | grep -v -e "^[ \t]*$" | wc -l
/bin/echo "========================"
/bin/echo -n "TOTAL: "; cat ${SCHEMA_MODELS} ${GRAMMAR_MODELS} ${FORMAT_MODELS} ${WEB_MODELS} ${SECURITY_MODELS} ${DIAGRAM_MODELS} ${EXPRESSION_MODELS} | grep -v -e "^[ \t]*$" | wc -l
echo
echo



PIPING_CODE="applications/Piping/code"

PIPING_MODELS="applications/Piping/models/controller.grammar \
	applications/Piping/models/controller.schema \
	applications/Piping/models/controller.stencil \
	applications/Piping/models/piping-sim.schema \
	applications/Piping/models/piping-sim.stencil \
	applications/Piping/models/piping.grammar \
	applications/Piping/models/piping.schema \
	applications/Piping/models/piping.stencil" 

/bin/echo "**** PIPING *****"

/bin/echo -n "PIPING_CODE: "; ${CLOC} ${PIPING_CODE} | grep -e "^SUM" | awk "{print \$5}"
/bin/echo -n "PIPING_MODELS:"; cat ${PIPING_MODELS} | grep -v -e "^[ \t]*$" | wc -l


