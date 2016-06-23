# frozen_string_literal: true
require 'named_validations/version'

# Naming to ActiveModel/ActiveRecord validations
class NamedValidations < Hash
  # Reserved names
  RESERVED = %i(
    extractable_options?
    class inspect
    merge deep_merge
    deep_merge_internal
  ).freeze
  private_constant :RESERVED

  class << self
    # @overload define(name, validation, params)
    #   Defines a new simple alias (define-by-value)
    #   @param name [Symbol] new alias name
    #   @param validation [Symbol] validation name or defined alias name
    #   @param params [Object] parameters or arguments for validation
    # @overload define(name, block)
    #   Defines a new alias by block (define-by-block)
    #   @param name [Symbol] new alias name
    #   @param block [Proc] body of alias
    def define(name, *spec, &block)
      raise ArgumentError, "reserved name #{name}" if RESERVED.include?(name)
      return define_by_block(name, block) if spec.empty?

      validation, params, = spec
      define_by_value(name, validation, params)
    end

    # Returns list of defined alias names
    # @return [Array<Symbol>]
    def aliases
      @aliases ||= []
    end

    private

    def inherited(sub_class)
      # Merge defined alias names list
      aliases.each { |name| sub_class.aliases << name }
    end

    def define_by_block(name, block)
      define_method(name, block)
      aliases << name
      name
    end

    def define_by_value(name, validation, params)
      raise ArgumentError,
            "unknown alias #{name}" unless aliases.include?(validation)

      block = -> (*opts) { public_send(validation, params, *opts) }
      define_by_block(name, block)
    end

    # Defines aliases for ActiveModel/ActiveRecord validations
    # @!macro attach define_for
    #   Apply `$1` to `self` and return a new object
    #   @!method $1(arg, *opts)
    #   @return [NamedValidations]
    def define_for(name)
      define(name) { |arg, *opts| deep_merge(name, arg, *opts) }
    end
  end

  define_for :absence
  define_for :confirmation
  define_for :format
  define_for :inclusion
  define_for :numericality
  define_for :acceptance
  define_for :exclusion
  define_for :length
  define_for :presence
  define_for :uniqueness
  define_for :associated
  define_for :size

  # Defines an alias for default options
  define(:defaults) { |default_opts| merge(default_opts) }

  # Returns true
  #
  # @note This method is needed for ActiveSupport `Hash#extract_options!`.
  def extractable_options?
    true
  end

  # Inspects self
  def inspect
    klass = self.class
    class_name = klass.name ||
                 Kernel.format('(Anonymous:0x%x)', klass.object_id)
    Kernel.format('#<%s:0x%x>', class_name, object_id)
  end

  protected

  # Returns a new object containing the given validations
  # and the current validations.
  def deep_merge(validation, params, *opts)
    new_obj = deep_merge_internal(validation, params)
    opts.inject(new_obj) { |obj, opt| obj.deep_merge(validation, opt) }
  end

  private

  def deep_merge_internal(validation, params)
    cur_params = self[validation]
    if !params.is_a?(Hash) || !cur_params.is_a?(Hash)
      new_params = params
    else
      new_params = params.inject(cur_params) do |hash, (key, value)|
        hash.merge(key => value)
      end
    end

    merge(validation => new_params)
  end
end
