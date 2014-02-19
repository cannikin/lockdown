set :database, 'sqlite://lockdown.db'

# define database migrations. pending migrations are run at startup and
# are guaranteed to run exactly once per database.
migration "create sensors" do
  database.create_table :sensors do
    primary_key :id
    integer     :sensor_id
    string      :type
    boolean     :state
    timestamp   :updated_at, :null => false

    index :sensor_id, :unique => true
  end
end

migration "create layouts" do
  database.create_table :layouts do
    primary_key :id
    integer     :sensor_id
    integer     :left
    integer     :top
    string      :orientation
  end
end

# you can also alter tables
# migration "everything's better with bling" do
#   database.alter_table :foos do
#     drop_column :baz
#     add_column :bling, :float
#   end
# end
