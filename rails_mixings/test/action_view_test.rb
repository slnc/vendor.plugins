require File.dirname(__FILE__) + '/../../../../test/test_helper'

class ActionViewTestContainer
  include ActionViewMixings
end

class ActionViewTest < Test::Unit::TestCase
  def test_clean_html_shouldnt_mess_up_mailto_links
    str = '<a href="mailto:dharana@dharana.net">dharana@dharana.net</a>'
    assert_equal str, ActionViewTestContainer.new.clean_html(str).strip
  end
  
  #def test_print_interval
  #  assert_equal '2 semanas', ActionViewTestContainer.new.format_interval(Time.now - 2.weeks.ago, 'horas', true).strip
  #end
end

