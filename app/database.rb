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
    String      :type
    Text        :data
    DateTime    :created_at, :null => false
  end
end

migration "add base_state to sensors" do
  database.add_column :sensors, :base_state, Integer, :default => 0
end

migration "add name to sensors" do
  database.add_column :sensors, :name, String
end

migration "create behaviors" do
  database.create_table :behaviors do
    primary_key :id
    String      :mode
    Boolean     :chime_on_sensor_change_from_base_state
    Boolean     :text_on_sensor_change_from_base_state
    Boolean     :chime_on_motion
    Boolean     :text_on_motion
  end
end

migration "add text numbers to settings" do
  database.add_column :settings, :text_numbers, String
end

migration 'create users table' do
  database.create_table :users do
    primary_key :id
    String      :username
    String      :password
  end
end

migration 'add phone numbers to settings' do
  database.alter_table :settings do
    rename_column :text_numbers, :contact_numbers
    add_column    :from_phone_number, String
  end
end

migration 'add image directory and s3 config to settings' do
  database.alter_table :settings do
    add_column :image_upload_path, String
    add_column :s3_bucket, String
    add_column :s3_access_key_id, String
    add_column :s3_secret_access_key, String
  end
end

migration 'add mail settings' do
  database.alter_table :settings do
    add_column :mandrill_api_key, String
  end
end

migration 'add twilio settings' do
  database.alter_table :settings do
    add_column :twilio_account_sid, String
    add_column :twilio_auth_token, String
  end
end

migration 'add contact_emails to settings' do
  database.alter_table :settings do
    add_column    :contact_emails, String
  end
end

migration 'add from_email to settings' do
  database.alter_table :settings do
    add_column    :from_email, String
  end
end

migration 'adds access_key to settings' do
  database.alter_table :settings do
    add_column :access_key, String
  end
end


# you can also alter tables
# migration "everything's better with bling" do
#   database.alter_table :foos do
#     drop_column :baz
#     add_column :bling, :float
#   end
# end
