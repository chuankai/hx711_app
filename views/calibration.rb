require 'singleton'

class CalibratedPoint
	attr_accessor :val, :raw

	def initialize(val, raw)
		@val, @raw = val, raw;
	end
end

class Calibration
	include Singleton

	def initialize
		@calibrated = false
		@num_of_entry = 5
		@calibration_points = Array.new(@num_of_entry)
	end

	def load_calibration_data
		# load calibration data
		@calibrated = true
	end

	def clear_calibration_data
		@calibrated = false
		@calibration_points.clear
	end

	def save_calibration_data
	end

	def add_value_raw(val, raw)
		if (@calibrated == false)
			p = CalibratedPoint.new(val, raw)
			@calibration_points << p
			if (@calibration_points.length == @num_of_entry)
				@calibration_points.sort! do |a, b|
					a.raw <=> b.raw
				end
				@calibrated = true
			end
			return true
		end
		return false		
	end

	def value_from_raw(raw)
		p_high = @calibration_points.bsearch { |x| x.raw >= raw }
		if (p_high == nil)
			'Out of scale'
		elsif (@calibration_points.index(p_high) == 0)
			'----'
		else
			p_low = @calibration_points[@calibration_points.index(p_high) - 1]
			r = Rational((raw - p_low.raw ), (p_high.raw - p_low.raw))
			(r * p_high.val + (1 - r) * p_low.val).to_f
		end
	end
end