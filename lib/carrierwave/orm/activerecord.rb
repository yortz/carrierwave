# encoding: utf-8

require 'active_record'

module CarrierWave
  module ActiveRecord

    include CarrierWave::Mount

    ##
    # See +CarrierWave::Mount#mount_uploader+ for documentation
    #
    def mount_uploader(column, uploader, options={}, &block)
      super

      alias_method :read_uploader, :read_attribute
      alias_method :write_uploader, :write_attribute

      validates_integrity_of column if uploader_option(column.to_sym, :validate_integrity)
      validates_processing_of column if uploader_option(column.to_sym, :validate_processing)
      
      after_save "store_#{column}!", :unless => :delayed_by_carrierwave? # only if is not delayed
      before_save "write_#{column}_identifier"
      after_destroy "remove_#{column}!" #, :unless => :delayed_by_carrierwave? # the deleted method should be sended as a complete background task ie:. @image.push(:destroy!)
    end
    

    ##
    # Makes the record invalid if the file couldn't be uploaded due to an integrity error
    #
    # Accepts the usual parameters for validations in Rails (:if, :unless, etc...)
    #
    # === Note
    #
    # Set this key in your translations file for I18n:
    #
    #     carrierwave:
    #       errors:
    #         integrity: 'Here be an error message'
    #
    def validates_integrity_of(*attrs)
      options = attrs.last.is_a?(Hash) ? attrs.last : {}
      validates_each(*attrs) do |record, attr, value|
        if record.send("#{attr}_integrity_error")
          message = options[:message] || I18n.t('carrierwave.errors.integrity', :default => 'is not an allowed type of file.')
          record.errors.add attr, message
        end
      end
    end

    ##
    # Makes the record invalid if the file couldn't be processed (assuming the process failed
    # with a CarrierWave::ProcessingError)
    #
    # Accepts the usual parameters for validations in Rails (:if, :unless, etc...)
    #
    # === Note
    #
    # Set this key in your translations file for I18n:
    #
    #     carrierwave:
    #       errors:
    #         processing: 'Here be an error message'
    #
    def validates_processing_of(*attrs)
      options = attrs.last.is_a?(Hash) ? attrs.last : {}
      validates_each(*attrs) do |record, attr, value|
        if record.send("#{attr}_processing_error")
          message = options[:message] || I18n.t('carrierwave.errors.processing', :default => 'failed to be processed.')
          record.errors.add attr, message
        end
      end
    end

  end # ActiveRecord
end # CarrierWave

ActiveRecord::Base.send(:extend, CarrierWave::ActiveRecord)


module DelayedActiveRecordExtensions
    def self.included(base)
      base.extend(ClassMethods)
    end

    def delayed_by_carrierwave?
      options = self.class.instance_variable_get("@uploader_options").first[1]
      return unless options
      if options.has_key?:delayed 
        return options[:delayed]
      else
        return
      end
    end

    module ClassMethods
   end
 end
 # include the extension 
ActiveRecord::Base.send(:include, DelayedActiveRecordExtensions)
