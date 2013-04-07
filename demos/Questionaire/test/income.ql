import prelude.ql

title "House buying survey"

hasSoldHouse: "Did you sell a house in 2010?" boolean
hasBoughtHouse: "Did you buy a house in 2010?" boolean
hasMaintLoan: "Did you enter a loan for maintenance/reconstruction?" money

if (hasSoldHouse) {
  location: "In which cities have you sold a house?" locations
  sellingPrice: "Price the house was sold for:" money
  privateDebt: "Private debts for the sold house:" money
  valueResidue: "Value residue:" value
}

answers

locations : str [ "Austin" "Amsterdam" "Cambridge" ]
value : int = sellingPrice.value
