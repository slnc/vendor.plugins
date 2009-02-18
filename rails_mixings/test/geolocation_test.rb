require File.dirname(__FILE__) + '/../../../../test/test_helper'
require 'RMagick'

class GeolocationTest < Test::Unit::TestCase
  def test_should_properly_resolve_known_ip
    assert_equal 'es', Geolocation.country_code_by_addr('87.217.161.31')
  end
  
  def test_resolve_ad_mode_should_properly_return_es_for_es_ip
    assert_equal 'es', Geolocation.resolve_ad_mode('87.217.161.31')
  end
  
  def test_resolve_ad_mode_should_properly_return_sa_for_ve_ip
    assert_equal 'sa', Geolocation.resolve_ad_mode('150.188.229.4')
  end

end
