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
    instance         = model_instance
    attributes_keys  = instance.attributes.keys
    reflections_keys = instance.reflections.keys
    mapped           = assert{ instance.to_map }
    assert{ attributes_keys.all? { | key | mapped.has_key? key } }
    assert{ reflections_keys.all? { | key | ! mapped.has_key?( key ) } }
  end

  testing 'calling to_map with true includes relations' do
    instance         = model_instance
    reflections_keys = instance.reflections.keys
    mapped           = assert{ instance.to_map( true ) }
    assert{ reflections_keys.all? { | key | mapped.has_key? key } }
  end

protected

  def model_instance
    klass = assert{ Class.new( ActiveRecord::Base ) }
    assert{ klass.new }
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
