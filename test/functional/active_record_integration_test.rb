# -*- encoding : utf-8 -*-
require 'testing'
require 'map'

require 'fake_active_record'
require 'map/integrations/active_record'

Testing Map::Integrations::ActiveRecord do
  testing 'requiring ActiveRecord integration automatically includes integration' do
    assert{ ActiveRecord::Base.ancestors.include?( Map::Integrations::ActiveRecord ) }
  end

  testing 'calling to_map includes only attributes by default' do
    instance        = model_instance
    attributes_keys = instance.class.column_names
    mapped          = assert{ instance.to_map }
    assert{ attributes_keys.all? { | key | mapped.has_key? key } }
  end

  testing 'calling to_map with include-type options includes relations' do
    instance = model_instance
    include_opts = [ :include , :includes , :with ]

    include_opts.each do | include_opt |
      key    = :r1
      mapped = assert{ instance.to_map( include_opt => key ) }
      assert{ mapped.has_key? key }
    end
  end

  testing 'calling to_map with exclude-type options excludes relations' do
    instance = model_instance
    exclude_opts = [ :exclude , :excludes , :without ]

    exclude_opts.each do | exclude_opt |
      key    = :name
      mapped = assert{ instance.to_map( exclude_opt => key ) }
      assert{ !mapped.has_key?( key ) }
    end
  end

  testing 'calling to_map with `with` option pointing at non-column method name includes returned val' do
    instance    = model_instance
    include_opt = :with
    key         = :bogus
    val         = instance.send key
    mapped      = assert{ instance.to_map( include_opt => key ) }
    assert{ mapped.send( key ) == val }
  end

  testing 'calling with multiple option types performs all' do
    instance    = model_instance
    with_key    = :bogus
    without_key = :model
    mapped      = assert{ instance.to_map( :includes => with_key , :without => without_key ) }
    assert{ mapped.has_key? with_key }
    assert{ !mapped.has_key?( without_key ) }
  end

  testing 'calling with multiple of the same option types performs all' do
    instance       = model_instance
    with_key       = :bogus
    other_with_key = :r2
    mapped         = assert{ instance.to_map( :includes => with_key , :with => other_with_key ) }
    assert{ mapped.has_key? with_key }
    assert{ mapped.has_key? other_with_key }
  end

  testing 'nesting to_map options on relation key that responds to to_map respects options' do
    instance        = model_instance true
    relation        = :r1
    nested_with_key = :bogus
    mapped          = assert{ instance.to_map( :include => { relation => { :with => nested_with_key } } ) }
    assert{ mapped[ relation ].has_key? nested_with_key }
  end

  testing 'including multiple where one has options respects all' do
    instance = model_instance true
    mapped   = assert{ instance.to_map( :include => [ :r1 , { :r2 => { :with => :bogus } } ] ) }
    assert{ mapped.has_key? :r1 }
    assert{ mapped.has_key? :r2 }
    assert{ mapped[ :r2 ].all? { | r | r.has_key? :bogus } }
  end

protected

  def model_instance( *args )
    klass = assert{ Class.new ActiveRecord::Base }
    assert{ klass.new *args }
  end
end

BEGIN {
  testdir = File.dirname(File.expand_path(__FILE__))
  testlibdir = File.join(testdir, 'lib')
  rootdir = File.dirname(testdir)
  libdir = File.join(rootdir, 'lib')
  $LOAD_PATH.push(libdir) unless $LOAD_PATH.include?(libdir)
  $LOAD_PATH.push(testlibdir) unless $LOAD_PATH.include?(testlibdir)
}
