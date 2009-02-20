module Test::Unit::Assertions
  def overload_rake_for_tests
    load File.dirname(__FILE__) + '/overload_rake_for_tests.rb'
  end
  
  def get_task_names
    Rake.application.tasks.collect { |task| task.name }
  end
  
  def assert_cache_exists f
    assert_equal true, File.exists?("#{FRAGMENT_CACHE_PATH}/#{f}.cache"), "#{f}.cache DONT EXIST and it SHOULD"
  end
  
  def assert_cache_dont_exist f
    assert_equal false, File.exists?("#{FRAGMENT_CACHE_PATH}/#{f}.cache"), "#{f}.cache EXISTS and it SHOULD NOT"
  end
  
  def assert_count_increases(model, &block)
    m = :count
    begin
      initial_count = model.send(m)
    rescue
      m = :size
      initial_count = model.size
    end
    yield
    assert_equal initial_count + 1, model.send(m)
  end
  
  def assert_count_decreases(model, &block)
    m = :count
    begin
      initial_count = model.send(m)
    rescue
      m = :size
      initial_count = model.size
    end
    yield
    assert_equal initial_count - 1, model.send(m)
  end
  
  # Add more helper methods to be used by all tests here...
  def assert_valid_markup(markup=@response.body)
    ENV['MARKUP_VALIDATOR'] ||= 'tidy'
    case ENV['MARKUP_VALIDATOR']
      when 'w3c'
      # Thanks http://scottraymond.net/articles/2005/09/20/rails-xhtml-validation
      require 'net/http'
      response = Net::HTTP.start('validator.w3.org') do |w3c|
        query = 'fragment=' + CGI.escape(markup) + '&output=xml'
        w3c.post2('/check', query)
      end
      if response['x-w3c-validator-status'] != 'Valid'
        error_str = "XHTML Validation Failed:\n"
        parser = XML::Parser.new
        parser.string = response.body
        doc = parser.parse
        
        doc.find('//result/messages/msg').each do |msg|
          error_str += "  Line %i: %s\n" % [msg['line'], msg]
        end
        
        flunk error_str
      end
      
      when 'tidy', 'tidy_no_warnings'
      require 'tidy'
      Tidy.path = defined?(App.tidy_path) ? App.tidy_path : '/usr/lib/libtidy.so'
      errors = []
      Tidy.open(:input_xml => true) do |tidy|
        tidy.clean(markup)
        errors.concat(tidy.errors)
      end
      Tidy.open(:show_warnings => false) do |tidy|
        tidy.clean(markup)
        errors.concat(tidy.errors)
      end
      if errors.length > 0
        error_str = ''
        errors.each do |e|
          error_str += e.gsub(/\n/, "\n  ")
        end
        out = ''
        i = 1
        markup.split("\n").each { |l| out << i.to_s << ': ' << l << "\n"; i += 1 }
        error_str = "XHTML Validation Failed:\n  #{out}\n\n#{error_str}"
        
        assert_block(error_str) { false }
      end
    end
  end
  
  def assert_valid_feed2(content=@response.body)
    validate = "#{RAILS_ROOT}/script/feedvalidator2/demo.py"
    path = Pathname.new("#{RAILS_ROOT}/tmp")
    Tempfile.open('feed', path.cleanpath) do |tmpfile|
      tmpfile.write(content)
      tmpfile.flush
      if App.platform == WINDOWS
        result = `python "#{validate.gsub('/', '\\')}" "file:///#{tmpfile.path.gsub('/', '\\')}" A`
      else
        result = `python "#{validate}" "#{tmpfile.path}" A`
      end
      unless result =~ /No errors or warnings/
        out = ''
        i = 1
        content.split("\n").each { |l| out << i.to_s << ': ' << l << "\n"; i += 1 }
        raise "Feed did not validate: #{result}\n#{out}"
      end
    end
  end
  
  # Custom assertions for cookies
  #
  #   assert_cookie :pass, 
  #     :value => lambda { |value| UUID.parse(value).valid? }
  #
  #   assert_cookie :yellow, :value => ['sunny', 'days']
  #
  #   assert_cookie :delight, :value => 'yum'
  #
  #   assert_cookie :secret, :path => lambda { |path| path =~ /secret/ }, 
  #     :secure => true   
  def assert_cookie(name, options={}, message="")
    clean_backtrace do
      cookie = cookies[name.to_s]
      
      msg = build_message(message, "expected cookie named <?> but it was not found.", name)
      assert_not_nil cookie, msg
      
      case 
        when options[:value].respond_to?(:call)
        msg = build_message(message,
                    "expected result of value block to be true but it was false.")
        cookie.value.each do |value|
          assert(options[:value].call(value), msg)
        end
        when options[:value].respond_to?(:each)
        options[:value].each do |value|
          msg = build_message(message, 
                      "expected cookie value to include <?> but it was not found.", value)
          assert(cookie.value.include?(value), msg)
        end
      else
        msg = build_message(message, "expected cookie value to be <?> but it was <?>.",
        options[:value], cookie.value)
        assert(cookie.value.include?(options[:value]), msg)
      end if options.key?(:value)
      
      assert_call_or_value :path, options, cookie, message
      assert_call_or_value :domain, options, cookie, message
      assert_call_or_value :expires, options, cookie, message
      assert_call_or_value :secure, options, cookie, message
    end
  end
  
  # Tests that a cookie named +name+ does not exist. This is useful
  # because cookies['name'] may be nil or [] in a functional test.
  #
  # assert_no_cookie :chocolate
  def assert_no_cookie(name, message="")
    cookie = cookies[name.to_s]
    msg = build_message(message, "no cookie expected but found <?>.", name)
    assert_block(msg) { cookie.nil? or (cookie.kind_of?(Array) and cookie.blank?) }
  end
  
  protected
  def assert_call_or_value(name, options, cookie, message="")
    case
      when options[name].respond_to?(:call)
      msg = build_message(message, 
                  "expected result of <?> block to be true but it was false.", name.to_s)
      assert(options[name].call(cookie.send(name)), msg)
    else
      msg = build_message(message, "expected cookie <?> to be <?> but it was <?>.",
      name.to_s, options[name], cookie.send(name))
      assert_equal(options[name], cookie.send(name), msg)
    end if options.key?(name)
  end
  
end
