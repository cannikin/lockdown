require 'listen'

class Uploader

  attr_reader :path, :bucket, :last, :listener, :s3, :callback

  def initialize(config, options={})
    @path = config.image_upload_path
    @bucket = config.s3_bucket
    @callback = options[:callback]
    @last = []
    @uploading = false
    setup_listener
    setup_s3(config.s3_access_key_id, config.s3_secret_access_key)
    listener.start
      $logger.debug "Uploader: Watching for new files in #{path}."
  end

  def upload(files)
    @last = []
    @uploading = true
    files.each do |f|
      if File.exists? f
        file = File.new(f)
        filename = file.path.split('/').last
          $logger.debug "Uploader: Uploading file #{file.path}..."
        object = s3.objects[filename].write(file, :acl => :public_read)
          $logger.debug "Uploader: Upload of #{file.path} complete. URL: #{object.public_url}"
          $logger.debug "Uploader: Deleting local file #{file.path}"
        File.delete(file)
        @last << object.public_url
      else
        $logger.debug "Uploader: Skipping missing file #{f}"
      end
    end
    @uploading = false
    callback.call(@last) if callback
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
