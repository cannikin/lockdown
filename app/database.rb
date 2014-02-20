set :database, 'sqlite://db/lockdown.db'

migration "create sensors" do
  database.create_table :sensors do
    primary_key :id
    String      :arduino_id
    String      :type
    Integer     :value
    DateTime    :updated_at, :null => false

    index :arduino_id, :unique => true
  end
end

migration "create layouts" do
  database.create_table :layouts do
    primary_key :id
    Integer     :sensor_id
    Integer     :left
    Integer     :top
    String      :orientation
  end
end

migration "create settings" do
  database.create_table :settings do
    primary_key :id
    String      :mode
  end
end

migration "create events" do
  database.create_table :events do
    primary_key :id
    Integer     :arduino_id
    String      :type
    String      :value
    Integer     :millis
    DateTime    :created_at, :null => false
  end
end


# you can also alter tables
# migration "everything's better with bling" do
#   database.alter_table :foos do
#     drop_column :baz
#     add_column :bling, :float
#   end
# end
