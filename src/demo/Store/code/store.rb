require 'core/system/load/load'
require 'core/schema/tools/print'

def print_reciept(order)
	puts "Company #{order.customer.store.name}"
	puts "Order #{order.id}"
	print_customer(order.customer)
	order.items.each do |item|
	  puts "#{item.quantity}:	#{item.product.name}	#{item.product.price}	#{item.total}"
  end
  puts "TOTAL #{order.total.round(2)}"
end

def print_customer(cust)
  puts "#{cust.first_name} #{cust.last_name}"
end

store = Load::load("Sample.store")
customer = store.customers["C1"]
order = customer.orders["A1"]
print_reciept(order)
