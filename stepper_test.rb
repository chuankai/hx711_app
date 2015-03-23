#!/usr/bin/ruby

require_relative 'stepper.rb'

motor = Stepper.new(0, 1, 3, 4, 0.01)
motor.run
sleep(6)
motor.stop
sleep(3)
puts 'main thread ends'

