To run the Questionaire demo (last edit 08apr13):

From enso/src:

1) Parse relevant to JSON: "ruby parseToJSON.rb"

2) Start web server: "js/run-web.sh"

3) Edit js/questionaire.htm so that it references the correct .ql file
   Demo for LWC 2013 is 'housing.ql'

4) Open http://localhost:8000/js/questionaire.htm. 
   Prefer Chrome but FF may work as well.
   Clear cache in browser if needed, Chrome caches JSON files
