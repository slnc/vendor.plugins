require 'test_helper'

class SlncTaxonomiesTest < ActiveSupport::TestCase
  
  def setup
      Term.class_eval do
        def self.taxonomies
          ['District']
        end
      end
  end
  
  test "plugin load" do
    assert_kind_of Term, Term.new 
  end
  
  test "should be able to create term" do
    t = Term.new(:name => 'foo', :taxonomy => 'District')
    assert t.save, t.errors.full_messages_html
  end
end
