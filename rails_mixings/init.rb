ActiveRecord::Base.send :include, ActiveRecordMixings
ActionView::Base.send :include, ActionViewMixings

$:.unshift "#{File.dirname(__FILE__)}/lib"
require 'test_unit'
require 'stats'
require 'notification'
require 'action_mailer' # TODO esto creo que no hace nada
# require 'action_controller' # TODO esto creo que no hace nada