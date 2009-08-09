module ActiveRecord
  module Validations

    def self.included(base)
      base.class_eval do
        alias_method :save, :new_save_with_validation
      end
    end

    module ClassMethods
      mattr_accessor :when_groups

      DEFAULT_VALIDATION_OPTIONS = {
        :on => :save,
        :allow_nil => false,
        :allow_blank => false,
        :message => nil,
        :when => nil
      }.freeze

      def validates_each(*attrs)
        options = attrs.extract_options!.symbolize_keys
        attrs   = attrs.flatten
        groups  = options[:when]

        # Declare the validation.
        send(validation_method(options[:on] || :save), options) do |record|
          attrs.each do |attr|
            value = record.send(attr)
            next if (value.nil? && options[:allow_nil]) || (value.blank? && options[:allow_blank]) || (skip_validate?(groups))
            yield record, attr, value
          end
        end
      end

      def validates_presence_of(*attr_names)
        configuration = { :on => :save }
        configuration.update(attr_names.extract_options!)
        groups = configuration[:when]

        send(validation_method(configuration[:on]), configuration) do |record|
          record.errors.add_on_blank(attr_names, configuration[:message]) unless skip_validate?(groups)
        end
      end

      # Check if validation should take place
      def skip_validate?(groups)
        groups = [*groups] unless groups.blank?

        if when_groups.blank? || groups.blank?
          return false
        else
          groups.each do |group| 
            return false if when_groups.include?(group.to_s)
          end
        end
        true
      end
    end

    def new_save_with_validation(perform_validation = true)
      unless (perform_validation == true) || (perform_validation == false)
        set_when_groups(perform_validation)
      end
      if perform_validation && valid? || !perform_validation
        save_without_validation
      else
        false
      end
    end

    private
      def set_when_groups(*groups)
        ClassMethods.when_groups = (groups.is_a?(Array) ? [*groups.collect {|g| g.to_s}] : [groups.to_s])
      end
  end

  # module Callbacks
  # 
  #   def self.included(base)
  #     base.class_eval do
  #       alias_method :valid?, :new_valid_with_callbacks?
  #     end
  #   end
  # 
  #   def new_valid_with_callbacks?(*args)
  #     set_when_groups(args)
  # 
  #     return false if callback(:before_validation) == false
  #     if new_record? then result = callback(:before_validation_on_create) else result = callback(:before_validation_on_update) end
  #     return false if false == result
  # 
  #     result = valid_without_callbacks?
  # 
  #     callback(:after_validation)
  #     if new_record? then callback(:after_validation_on_create) else callback(:after_validation_on_update) end
  # 
  #     return result
  #   end
  # 
  #   private
  #     def set_when_groups(*groups)
  #       ActiveRecord::Validations::ClassMethods.when_groups = (groups.is_a?(Array) ? [*groups.collect {|g| g.to_s}] : [groups.to_s])
  #     end
  # end

  Base.class_eval do
    include Validations
    # include Callbacks
  end
end