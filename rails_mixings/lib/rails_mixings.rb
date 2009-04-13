if File.exists?("#{RAILS_ROOT}/config/initializers/pre_plugins.rb")
  require "#{RAILS_ROOT}/config/initializers/pre_plugins.rb"
end

$:.unshift "#{File.dirname(__FILE__)}/lib"

ActiveRecord::Base.send :include, ActiveRecordMixings
ActionView::Base.send :include, ActionViewMixings
ActionController::Base.send :include, ActionControllerMixings
User.send :include, UserMixings
Stats::Goals.send :include, StatsMixings::GoalsMixings

require 'test_unit_mixings'
require 'notification'
require 'action_mailer' # TODO esto creo que no hace nada
# require 'action_controller' # TODO esto creo que no hace nada

if nil

%w(active_record_mixings
ab_test
action_controller
action_mailer
action_view_mixings
friendship
geolocation
notification
overload_rake_for_tests
silenced_email
stats
test_unit
user).each do |mymodule|
  #require File.join(File.dirname(__FILE__), mymodule)
end
end
