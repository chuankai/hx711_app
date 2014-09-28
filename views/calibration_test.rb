require './calibration'

puts "==== Class Calibration Test ===="

c = Calibration.instance
c.load_calibration_data
c.clear_calibration_data

1.upto(5) do |i|
	c.add_value_raw((5 - i) * 100, (5 - i) * 10)
end

puts "Raw 13 => Value #{c.value_from_raw(13)}"

puts "Raw 40 => Value #{c.value_from_raw(40)}"

puts "Raw 0 => Value #{c.value_from_raw(0)}"

puts "Raw 1 => Value #{c.value_from_raw(1)}"

puts "Raw 50 => Value #{c.value_from_raw(50)}"

puts "Raw -10 => Value #{c.value_from_raw(-10)}"
