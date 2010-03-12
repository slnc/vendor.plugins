require 'test_helper'

class SlncTaxonomiesTest < ActiveSupport::TestCase
  test "plugin load" do
    assert_kind_of Term, Term.new 
  end
  
  test "should be able to create term" do
    t = Term.new(:name => 'foo', :taxonomy => 'District')
    assert t.save
  end
end
