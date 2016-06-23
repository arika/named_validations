# frozen_string_literal: true
require 'test_helper'

class NamedValidationsTest < Test::Unit::TestCase
  setup do
    @vals = Class.new(NamedValidations)

    @vals.class_exec(@vals) do |vals|
      define :testing, :presence, true
      define :overwrite, :presence, false

      define :other_value1, :acceptance, true
      define :other_value2, :acceptance, 'foo'
      define :other_opts1, :acceptance, if: false
      define :other_opts2, :acceptance, if: true, unless: true

      define :nesting, :other_opts1, if: true, allow_blank: true

      define :block1 do
        deep_merge(:presence, true)
      end

      define :block2 do
        deep_merge(:presence, false)
      end

      define :block3 do
        block1.block2
      end

      define :reset do
        vals.new
      end

      define :arg0 do
        deep_merge(:presence, true)
      end

      define :arg1 do |opt|
        deep_merge(:presence, opt)
      end

      define :arg2 do |opt1, opt2 = false|
        deep_merge(:presence, opt1)
          .deep_merge(:acceptance, opt2)
      end
    end
  end

  aliases = {
    # data_name: [:alias_name, [alias_args], { expected_validations }]
    testing: [:testing, [], { presence: true }],
    overwrite: [:overwrite, [], { presence: false }],
    other_value1: [:other_value1, [], { acceptance: true }],
    other_value2: [:other_value2, [], { acceptance: 'foo' }],
    other_opts1: [:other_opts1, [], { acceptance: { if: false } }],
    other_opts2: [:other_opts2, [], { acceptance: { if: true, unless: true } }],
    nesting: [:nesting, [], { acceptance: { if: true, allow_blank: true } }],
    block1: [:block1, [], { presence: true }],
    block2: [:block2, [], { presence: false }],
    block3: [:block3, [], { presence: false }],
    reset: [:reset, [], {}],
    arg0: [:arg0, [], { presence: true }],
    arg1: [:arg1, [1], { presence: 1 }],
    arg2_1: [:arg2, [2], { presence: 2, acceptance: false }],
    arg2_2: [:arg2, [3, 4], { presence: 3, acceptance: 4 }]
  }

  test 'instance is a Hash' do
    assert_kind_of Hash, @vals.new
    assert_instance_of @vals, @vals.new
  end

  test 'extractable_options? return true' do
    assert @vals.new.extractable_options?
  end

  test 'pre-defined alias' do
    expected = %w(
      absence acceptance associated confirmation exclusion format inclusion
      length numericality presence size uniqueness defaults
    ).sort
    pre_defined = NamedValidations.aliases.map(&:to_s).sort
    assert_equal expected, pre_defined
  end

  test 'default options' do
    vals = @vals.new
    assert_equal true, vals.defaults(if: true)[:if]

    obj = vals.length(maximum: 10, minmum: 1).defaults(length: { foo: :bar })
    assert_equal({ foo: :bar }, obj[:length])
  end

  sub_test_case 'defining alias' do
    base_aliases = NamedValidations.aliases
    defined_aliases = aliases.values.map { |name,| name }.uniq

    test 'list defined aliases' do
      expected = base_aliases + defined_aliases
      assert_equal expected, @vals.aliases

      sub = Class.new(@vals)
      assert_equal expected, sub.aliases

      sub.define :sub_testing, :presence, true
      assert_equal expected + [:sub_testing], sub.aliases

      assert_equal expected, @vals.aliases
    end

    data(defined_aliases.map { |name| [name, name] })
    test 'define defines a method' do |name|
      assert_respond_to @vals.new, name
    end

    data(aliases)
    test 'returned object includes the pair' do |(name, args, validations)|
      obj = @vals.new.public_send(name, *args)
      validations.each do |val, param|
        assert_include obj, val
        assert_equal param, obj[val]
      end
    end

    test 'defined method returns a new object' do
      assert_instance_of @vals, @vals.new.testing
    end

    test 'define-by-value accepts named validations only' do
      assert_raise ArgumentError do
        @vals.define :new_name, :unknown, true
      end
    end
  end

  sub_test_case 'arguments for aliases defined with a value' do
    test 'argument is merged to definition value' do
      base = @vals.new
      assert_equal false, base.testing(false)[:presence]
      assert_equal true, base.other_opts1(true)[:acceptance]
      assert_equal true, base.other_opts1(if: true)[:acceptance][:if]
      assert_equal 'foo', base.nesting(if: 'foo')[:acceptance][:if]
    end
  end

  sub_test_case 'arguments for aliases defined with a block' do
    test 'arguments is passed to block' do
      base = @vals.new
      assert_equal true, base.arg0[:presence]
      assert_equal 'foo', base.arg1('foo')[:presence]

      obj = base.arg2('foo', 'bar')
      assert_equal 'foo', obj[:presence]
      assert_equal 'bar', obj[:acceptance]
    end
  end

  sub_test_case 'alias chain' do
    setup do
      @base = @vals.new
    end

    test 'merge pairs' do
      obj = @base.testing.other_value1
      assert_equal true, obj[:presence]
      assert_equal true, obj[:acceptance]
    end

    test 'overwrite values' do
      assert_equal false, @base.testing.overwrite[:presence]
      assert_equal true, @base.testing.overwrite.testing[:presence]
    end

    test 'overwrite by other type value' do
      obj = @base.other_value1.other_opts1
      assert_equal({ if: false }, obj[:acceptance])

      obj = @base.other_opts1.other_value1
      assert_equal true, obj[:acceptance]
    end

    test 'deep merge' do
      obj = @base.other_opts1.other_opts2
      assert_equal({ if: true, unless: true }, obj[:acceptance])

      obj = obj.other_opts1
      assert_equal({ if: false, unless: true }, obj[:acceptance])
    end

    test 'split chain' do
      obj = @base.testing.other_value1.reset.other_value2
      assert_equal 'foo', obj[:acceptance]
      assert_false obj.include?(:presence)
    end
  end

  sub_test_case 'inspection' do
    test 'inspect anonymous validations class instances' do
      obj = @vals.new
      expected = format('#<(Anonymous:0x%x):0x%x>',
                        @vals.object_id, obj.object_id)
      assert_equal expected, obj.inspect
    end

    class TestingVals < NamedValidations
    end

    test 'inspect named validations class instances' do
      obj = TestingVals.new
      expected = format('#<%s:0x%x>', TestingVals, obj.object_id)
      assert_equal expected, obj.inspect
    end
  end

  data(%i(
    class extractable_options? inspect
    merge deep_merge deep_merge_internal
  ).map { |name| [name, name] })
  test 'reserved name' do |name|
    assert_raise ArgumentError do
      @vals.define(name) {}
    end
  end
end
