require 'contest'
require 'tilt'

class StringTemplateTest < Test::Unit::TestCase
  test "registered for '.str' files" do
    assert_equal Tilt::StringTemplate, Tilt['test.str']
  end

  test "loading and evaluating templates on #render" do
    template = Tilt::StringTemplate.new { |t| "Hello World!" }
    assert_equal "Hello World!", template.render
  end

  test "passing locals" do
    template = Tilt::StringTemplate.new { 'Hey #{name}!' }
    assert_equal "Hey Joe!", template.render(Object.new, :name => 'Joe')
  end

  test "evaluating in an object scope" do
    template = Tilt::StringTemplate.new { 'Hey #{@name}!' }
    scope = Object.new
    scope.instance_variable_set :@name, 'Joe'
    assert_equal "Hey Joe!", template.render(scope)
  end

  test "passing a block for yield" do
    template = Tilt::StringTemplate.new { 'Hey #{yield}!' }
    assert_equal "Hey Joe!", template.render { 'Joe' }
    assert_equal "Hey Moe!", template.render { 'Moe' }
  end

  test "multiline templates" do
    template = Tilt::StringTemplate.new { "Hello\nWorld!\n" }
    assert_equal "Hello\nWorld!\n", template.render
  end

  test "backtrace file and line reporting without locals" do
    data = File.read(__FILE__).split("\n__END__\n").last
    fail unless data[0] == ?<
    template = Tilt::StringTemplate.new('test.str', 11) { data }
    begin
      template.render
      fail 'should have raised an exception'
    rescue => boom
      assert_kind_of NameError, boom
      line = boom.backtrace.first
      file, line, meth = line.split(":")
      assert_equal 'test.str', file
      assert_equal '13', line
    end
  end

  test "backtrace file and line reporting with locals" do
    data = File.read(__FILE__).split("\n__END__\n").last
    fail unless data[0] == ?<
    template = Tilt::StringTemplate.new('test.str', 1) { data }
    begin
      template.render(nil, :name => 'Joe', :foo => 'bar')
      fail 'should have raised an exception'
    rescue => boom
      assert_kind_of RuntimeError, boom
      line = boom.backtrace.first
      file, line, meth = line.split(":")
      assert_equal 'test.str', file
      assert_equal '6', line
    end
  end
end


class CompiledStringTemplateTest < Test::Unit::TestCase
  def teardown
    GC.start
  end

  class Scope
    include Tilt::CompileSite
  end

  test "compiling template source to a method" do
    template = Tilt::StringTemplate.new { |t| "Hello World!" }
    template.render(Scope.new)
    method_name = template.send(:compiled_method_name, [].hash)
    method_name = method_name.to_sym if Symbol === Kernel.methods.first
    assert Tilt::CompileSite.instance_methods.include?(method_name),
      "CompileSite.instance_methods.include?(#{method_name.inspect})"
    assert Scope.new.respond_to?(method_name),
      "scope.respond_to?(#{method_name.inspect})"
  end

  test "loading and evaluating templates on #render" do
    template = Tilt::StringTemplate.new { |t| "Hello World!" }
    assert_equal "Hello World!", template.render(Scope.new)
    method_name = template.send(:compiled_method_name, [].hash)
    assert Scope.new.respond_to?(method_name)
  end

  test 'garbage collecting compiled methods' do
    template = Tilt::StringTemplate.new { '' }
    method_name = template.send(:compiled_method_name, [].hash)
    template.render(Scope.new)
    assert Scope.new.respond_to?(method_name)
    Tilt::Template.send(
      :garbage_collect_compiled_template_method,
      Tilt::CompileSite,
      method_name
    )
    assert !Scope.new.respond_to?(method_name), "compiled method not removed"
  end

  test "passing locals" do
    template = Tilt::StringTemplate.new { 'Hey #{name}!' }
    assert_equal "Hey Joe!", template.render(Scope.new, :name => 'Joe')
    assert_equal "Hey Moe!", template.render(Scope.new, :name => 'Moe')
  end

  test "evaluating in an object scope" do
    template = Tilt::StringTemplate.new { 'Hey #{@name}!' }
    scope = Scope.new
    scope.instance_variable_set :@name, 'Joe'
    assert_equal "Hey Joe!", template.render(scope)
    scope.instance_variable_set :@name, 'Moe'
    assert_equal "Hey Moe!", template.render(scope)
  end

  test "passing a block for yield" do
    template = Tilt::StringTemplate.new { 'Hey #{yield}!' }
    assert_equal "Hey Joe!", template.render(Scope.new) { 'Joe' }
    assert_equal "Hey Moe!", template.render(Scope.new) { 'Moe' }
  end

  test "multiline templates" do
    template = Tilt::StringTemplate.new { "Hello\nWorld!\n" }
    assert_equal "Hello\nWorld!\n", template.render(Scope.new)
  end

  test "backtrace file and line reporting without locals" do
    data = File.read(__FILE__).split("\n__END__\n").last
    fail unless data[0] == ?<
    template = Tilt::StringTemplate.new('test.str', 11) { data }
    begin
      template.render(Scope.new)
      fail 'should have raised an exception'
    rescue => boom
      assert_kind_of NameError, boom
      line = boom.backtrace.first
      file, line, meth = line.split(":")
      assert_equal 'test.str', file
      assert_equal '13', line
    end
  end

  test "backtrace file and line reporting with locals" do
    data = File.read(__FILE__).split("\n__END__\n").last
    fail unless data[0] == ?<
    template = Tilt::StringTemplate.new('test.str') { data }
    begin
      template.render(Scope.new, :name => 'Joe', :foo => 'bar')
      fail 'should have raised an exception'
    rescue => boom
      assert_kind_of RuntimeError, boom
      line = boom.backtrace.first
      file, line, meth = line.split(":")
      assert_equal 'test.str', file
      assert_equal '6', line
    end
  end
end

__END__
<html>
<body>
  <h1>Hey #{name}!</h1>


  <p>#{fail}</p>
</body>
</html>
