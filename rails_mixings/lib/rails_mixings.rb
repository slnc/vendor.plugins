if File.exists?("#{RAILS_ROOT}/config/initializers/pre_plugins.rb")
  require "#{RAILS_ROOT}/config/initializers/pre_plugins.rb"
end

$:.unshift "#{File.dirname(__FILE__)}/lib"

ActiveRecord::Base.send :include, ActiveRecordMixings
ActionView::Base.send :include, ActionViewMixings
ActionController::Base.send :include, ActionControllerMixings
User.send :include, UserMixings
Notification.send :include, NotificationMixings
Stats::Goals.send :include, StatsMixings::GoalsMixings

require 'test_unit_mixings'