
hasSoldHouse: "Did you sell a house in 2010?" boolean
hasBoughtHouse: "Did you buy a house in 2010?" boolean
hasMaintLoan: "Did you enter a loan for maintenance/reconstruction?" boolean

if (hasSoldHouse) {
  sellingPrice: "Price the house was sold for:" money
  privateDebt: "Private debts for the sold house:" money
  valueResidue: "Value residue:" value
}

answers

MultiChoice boolean { "Yes" "No" }
TextBox money : int
Computed value : (sellingPrice - privateDebt)
