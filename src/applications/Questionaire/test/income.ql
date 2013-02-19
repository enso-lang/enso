
hasSoldHouse: "Did you sell a house in 2010?" boolean
hasBoughtHouse: "Did you buy a house in 2010?" boolean
hasMaintLoan: "Did you enter a loan for maintenance/reconstruction?" boolean

if (not hasSoldHouse) {
  sellingPrice: "Price the house was sold for:" money
  privateDebt: "Private debts for the sold house:" money
  valueResidue: "Value residue:" value
}

answers

boolean : bool ( "Yes" "No" )
locations : str [ "Austin" "Amsterdam" "Cambridge" ]
money : int 
value : int = (sellingPrice - privateDebt)
