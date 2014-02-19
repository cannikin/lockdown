class Sensor < Sequel::Model
  one_to_one :layout
end

class Layout < Sequel::Model
  one_to_one :sensor
end

class Setting < Sequel::Model
end
