require 'listen'

class Uploader

  attr_reader :path, :bucket, :last, :listener, :s3, :logger

  def initialize(options)
    @path = options[:path]
    @bucket = options[:bucket]
    @last = []
    @uploading = false
    @logger = Logger.new(STDOUT)
    setup_listener
    setup_s3(options[:access_key_id], options[:secret_access_key])
      logger.debug "Initialized Uploader."

    listener.start
      logger.debug "Watching for new files in #{path}."
  end

  def upload(files)
    @last = []
    @uploading = true
    files.each do |f|
      file = File.new(f)
      filename = file.path.split('/').last
        logger.debug "Uploading file #{file.path}..."
      object = s3.objects[filename].write(file, :acl => :public_read)
        logger.debug "Upload of #{file.path} complete. URL: #{object.public_url}"
        logger.debug "Deleting local file #{file.path}"
      File.delete(file)
      @last << object.public_url
    end
    @uploading = false
  end

  def uploading?
    @uploading
  end

private

  def setup_listener
    @listener = Listen.to(path) do |modified, added, removed|
      upload(added) if added.any?
    end
    EM.add_shutdown_hook { listener.stop }
  end

  def setup_s3(access_key_id, secret_access_key)
    AWS.config :access_key_id => access_key_id, :secret_access_key => secret_access_key
    @s3 = AWS.s3.buckets[bucket]
  end

end
