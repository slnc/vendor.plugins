# module ActionController
#class TestRequest < Request
# attr_accessor :user_agent
#end
#end


module ActionControllerMixings
  def self.included(base)
    base.class_eval do
      before_filter :init_xab
      include ActionControllerMixings::InstanceMethods
    end
  end
    
  module InstanceMethods
    def init_xab
      params['_xab'] = {} unless params['_xab']
      params['_xab'] = ActiveSupport::JSON.decode(CGI::unescape(params['_xab'])) if params['_xab'].kind_of?(String)
      params['_xab_new_treated_visitors'] = {}
      
      params['_xad'] = [] unless params['_xad']
      params['_xad'] = ActiveSupport::JSON.decode(CGI::unescape(params['_xad'])) if params['_xad'].kind_of?(String)
      
      params[:smodel_id] = params[:id] if !params[:smodel_id] && params[:id]
    end
  end
end

if RAILS_GEM_VERSION >= '2.1.0' then
  module ActionController::Caching::Fragments
    def fragment_cache_key(key)
      # quitar views/ de las keys
      ActiveSupport::Cache.expand_cache_key(key.is_a?(Hash) ? url_for(key).split("://").last : key, '')
    end
  end
end
