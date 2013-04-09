import prelude.ql

title "House buying survey"

"Did you sell a house in 2010?" boolean
"Did you buy a house in 2010?" boolean
"Did you enter a loan for maintenance/reconstruction?" money

"In which cities have you sold a house?" locations
"Price the house was sold for:" money
"Private debts for the sold house:" money

answers

locations : str [ "Austin" "Amsterdam" "Cambridge" ]