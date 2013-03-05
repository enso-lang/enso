import prelude.ql

hasSoldHouse: "Did you sell a house in 2010?" money
hasBoughtHouse: "Did you buy a house in 2010?" money
hasMaintLoan: "Did you enter a loan for maintenance/reconstruction?" money

if (hasSoldHouse) {
  sellingPrice: "Price the house was sold for:" money
  privateDebt: "Private debts for the sold house:" money
  valueResidue: "Value residue:" money
}

answers

locations : str [ "Austin" "Amsterdam" "Cambridge" ]
value : int = (sellingPrice - privateDebt)
