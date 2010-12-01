# encoding: utf-8

module CarrierWave
  module Uploader
    module Store

      depends_on CarrierWave::Uploader::Callbacks
      depends_on CarrierWave::Uploader::Configuration
      depends_on CarrierWave::Uploader::Cache

      ##
      # Override this in your Uploader to change the filename.
      #
      # Be careful using record ids as filenames. If the filename is stored in the database
      # the record id will be nil when the filename is set. Don't use record ids unless you
      # understand this limitation.
      #
      # Do not use the version_name in the filename, as it will prevent versions from being
      # loaded correctly.
      #
      # === Returns
      #
      # [String] a filename
      #
      def filename
        @filename
      end

      ##
      # Calculates the path where the file should be stored. If +for_file+ is given, it will be
      # used as the filename, otherwise +CarrierWave::Uploader#filename+ is assumed.
      #
      # === Parameters
      #
      # [for_file (String)] name of the file <optional>
      #
      # === Returns
      #
      # [String] the store path
      #
      def store_path(for_file=filename)
        File.join([store_dir])
      end

      ##
      # Stores the file by passing it to this Uploader's storage engine.
      #
      # If new_file is omitted, a previously cached file will be stored.
      #
      # === Parameters
      #
      # [new_file (File, IOString, Tempfile)] any kind of file object
      #
      def store!(new_file=nil)
        cache!(new_file) if new_file
        
        
        # pass the file from cache
        unless new_file
          if model.delayed_by_carrierwave?
            begin
              mounted_as_name = self.instance_variable_get("@mounted_as").to_s.downcase
              @file = CarrierWave::SanitizedFile.new("#{self.cache_dir}/#{self.model.send("#{mounted_as_name}_new_cache_name")}") 
              @file.instance_variable_set("@content_type", self.model.send("#{mounted_as_name}_content_type"))
              @file.instance_variable_set("@original_filename", self.model.send("#{mounted_as_name}_file_name"))
              @cache_id = self.model.send("#{mounted_as_name}_new_cache_name").to_s.split('/', 2)
              puts "NEW FILE: #{@file.to_json}"
              puts "CACHE ID: #{@cache_id}"
            rescue => e
              raise "Error assigning the cache file to the model, perhaps you need #{mounted_as_name}_content_type, #{mounted_as_name}_file_name, #{mounted_as_name}_cache_name field in your #{self.model.class} Class; #{e}"
            end
          end
        end     
        
        if @file and @cache_id
          with_callbacks(:store, new_file) do
            @file = storage.store!(@file)
            @cache_id = nil
          end
        end
      end

      ##
      # Retrieves the file from the storage.
      #
      # === Parameters
      #
      # [identifier (String)] uniquely identifies the file to retrieve
      #
      def retrieve_from_store!(identifier)
        with_callbacks(:retrieve_from_store, identifier) do
          @file = storage.retrieve!(identifier)
        end
      end

    private

      def full_filename(for_file)
        for_file
      end

      def storage
        @storage ||= self.class.storage.new(self)
      end

    end # Store
  end # Uploader
end # CarrierWave