require 'aws/s3'
module AttachmentFu
  class Tasks
    class S3
      include AWS::S3

      attr_reader :options

      class << self
        attr_reader :connection_options

        #   :access_key_id     => REQUIRED
        #   :secret_access_key => REQUIRED
        #   :server            => defaults to Amazon
        #   :use_ssl           => Use SSL, defaults to false
        #   :port              => Set this for custom ports.  80 or 443 is implied, depending on :use_ssl.
        #   :persistent        => Whether the S3 lib should use persistent connections or not.  
        #   :proxy             => http proxy for accessing S3
        def connect(options)
          o = options.slice(:access_key_id, :secret_access_key, :server, :port, :use_ssl, :persistent, :proxy)
          AWS::S3::Base.establish_connection!(o.dup) # establish_connection! modifies the hash
          @connection_options = o
        end

        def connected?
          !@connection_options.blank?
        end
      end

      # Some valid options:
      #
      #   # model-specific options
      #   :bucket_name       => REQUIRED
      #   :access            => defaults to :authenticated_read.  Other valid choices include: :public_read (common), :public_read_write, and :private.
      #
      #   # global connection options
      #   :access_key_id     => REQUIRED
      #   :secret_access_key => REQUIRED
      #   :server            => defaults to Amazon
      #   :use_ssl           => Use SSL, defaults to false
      #   :port              => Set this for custom ports.  80 or 443 is implied, depending on :use_ssl.
      #   :persistent        => Whether the S3 lib should use persistent connections or not.  
      #   :proxy             => http proxy for accessing S3
      #
      # AWS::S3 only supports one connection (why would you want to connect to multiple S3 hosts anyway?).  You can 
      # also send only the connection options to AttachmentFu::Tasks::S3.connect(...).
      #
      def initialize(klass, options)
        klass.class_eval do
          def s3
            @s3 ||= S3TaskProxy.new(self)
          end
        end

        @options = options
        @options.update(self.class.connection_options) if self.class.connected?
        self.class.connect(@options) unless self.class.connected?
      end

      def call(attachment, options = nil)
        options = options ? @options.merge(options) : @options
        attachment.s3.store
      end

      def exist?(attachment, thumbnail = nil, options = nil)
        options = options ? @options.merge(options) : @options
        S3Object.exists?(attachment.s3.path(thumbnail), options[:bucket_name])
      rescue Errno::EPIPE, Timeout::Error, Errno::EINVAL, EOFError, Errno::ECONNREFUSED
        self.class.connection_options.clear
        false
      end

      def store(attachment, options = nil)
        options = options ? @options.merge(options) : @options
        access  = if options[:access].respond_to?(:call)
          options[:access].call(attachment)
        else
          options[:access]
        end

        S3Object.store \
          attachment.s3.path,
          File.open(attachment.full_path),
          options[:bucket_name],
          :content_type => attachment.content_type,
          :access       => access || :authenticated_read
      rescue Errno::EPIPE, Timeout::Error, Errno::EINVAL, EOFError, Errno::ECONNREFUSED
        self.class.connection_options.clear
        nil
      end

      def rename(attachment, old_path, options = nil)
        options = options ? @options.merge(options) : @options
        S3Object.rename old_path, attachment.s3.path, options[:bucket_name]
      rescue Errno::EPIPE, Timeout::Error, Errno::EINVAL, EOFError, Errno::ECONNREFUSED
        self.class.connection_options.clear
        nil
      end

      def delete(attachment, options = nil)
        options = options ? @options.merge(options) : @options
        S3Object.delete attachment.s3.path, options[:bucket_name]
      rescue AWS::S3::NoSuchKey
      rescue Errno::EPIPE, Timeout::Error, Errno::EINVAL, EOFError, Errno::ECONNREFUSED
        self.class.connection_options.clear
        nil
      end

      def object_for(attachment, thumbnail = nil, options = nil)
        options = options ? @options.merge(options) : @options
        S3Object.find(attachment.s3.path(thumbnail), options[:bucket_name])
      rescue Errno::EPIPE, Timeout::Error, Errno::EINVAL, EOFError, Errno::ECONNREFUSED
        self.class.connection_options.clear
        nil
      end

      def acl_for(attachment, thumbnail = nil, options = nil)
        options = options ? @options.merge(options) : @options
        S3Object.acl(attachment.s3.path(thumbnail), options[:bucket_name])
      rescue Errno::EPIPE, Timeout::Error, Errno::EINVAL, EOFError, Errno::ECONNREFUSED
        self.class.connection_options.clear
        nil
      end

      def stream_for(attachment, thumbnail = nil, options = nil, &block)
        options = options ? @options.merge(options) : @options
        S3Object.stream(attachment.s3.path(thumbnail), options[:bucket_name], &block)
      rescue Errno::EPIPE, Timeout::Error, Errno::EINVAL, EOFError, Errno::ECONNREFUSED
        self.class.connection_options.clear
        nil
      end

      # For authenticated URLs, pass one of these options:
      #
      #   :expires_in => Defaults to 5 minutes.
      #   :auth or :authenticated => if true, create an authenticated URL.
      #
      def url_for(attachment, thumbnail = nil, options = nil)
        options = options ? @options.merge(options) : @options
        if options.key?(:expires_in) || options.key?(:auth) || options.key?(:authenticated)
          S3Object.url_for(attachment.s3.path(thumbnail), options[:bucket_name], options.slice(:expires_in, :use_ssl))
        else
          File.join(protocol(options) + hostname(options) + port_string(options), bucket_name(options), attachment.s3.path(thumbnail))
        end
      end

      def protocol(options = nil)
        options = options ? @options.merge(options) : @options
        @protocol ||= options[:use_ssl] ? 'https://' : 'http://'
      end

      def hostname(options = nil)
        options = options ? @options.merge(options) : @options
        @hostname ||= options[:server] || AWS::S3::DEFAULT_HOST
      end

      def port_string(options = nil)
        options = options ? @options.merge(options) : @options
        @port_string ||= (options[:port].nil? || options[:port] == (options[:use_ssl] ? 443 : 80)) ? '' : ":#{options[:port]}"
      end

      def bucket_name(options = nil)
        options = options ? @options.merge(options) : @options
        options[:bucket_name]
      end

      class S3TaskProxy
        def initialize(asset)
          @asset = asset
        end

        # For authenticated URLs, pass one of these options:
        #
        #   :expires_in => Defaults to 5 minutes.
        #   :auth or :authenticated => if true, create an authenticated URL.
        #
        def url(thumbnail = nil, options = {})
          if thumbnail.is_a?(Hash)
            options   = thumbnail
            thumbnail = nil
          end
          task.url_for(@asset, thumbnail, options)
        end

        # Retrieve the S3 object for the attachment path.
        #
        #   @attachment = Attachment.find 1
        #   open(@attachment.filename, 'wb') do |f|
        #     f.write @attachment.s3_object.value
        #   end
        #
        def object(thumbnail = nil)
          (@object ||= {})[thumbnail || :default] ||= task.object_for(@asset, thumbnail)
        end

        def object_exists?(thumbnail = nil)
          task.exist?(@asset, thumbnail)
        end

        # Stream the S3 object data.
        #
        #   @attachment = Attachment.find 1
        #   open(@attachment.filename, 'wb') do |f|
        #     @attachment.s3_stream(thumbnail) do |chunk|
        #       f.write chunk
        #     end
        #   end
        #
        def stream(thumbnail = nil, &block)
          task.stream_for(@asset, thumbnail, &block)
        end

        def store(options = nil)
          task.store(@asset, options)
          @asset.send(:delete_attachment)
        end

        def rename(old_name = @asset.renamed_filename)
          return if old_name.nil?
          task.rename(@asset, File.join(File.dirname(path), old_name))
          @object.clear if @object
        end

        def delete(options = nil)
          task.delete(@asset, options)
          @object.clear if @object
        end

        # The path used for working with S3.  By default it is the public path without the leading /.
        def path(thumbnail = nil)
          @asset.public_path(thumbnail)[1..-1]
        end

        def connected?
          !task.nil?
        end

        def options
          task.options
        end

        def task
          @asset.class.attachment_tasks[:s3]
        rescue ArgumentError
        end

        def inspect
          "<#{@asset.class} S3: #{path.inspect}, #{options.inspect}>"
        end
      end
    end
  end
end

# AttachmentFu::Tasks::S3.connect(:access_key_id => '...', :secret_key => '...', ...)
# task :s3, :bucket_name => 'snarf', :access => :authenticated_read
#
AttachmentFu.create_task :s3, AttachmentFu::Tasks::S3