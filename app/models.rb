class Behavior < Sequel::Model
end

class Event < Sequel::Model
end

class Layout < Sequel::Model
  one_to_one :sensor
end

class Sensor < Sequel::Model
  one_to_one :layout
end


class Setting < Sequel::Model
end

class User < Sequel::Model
end
