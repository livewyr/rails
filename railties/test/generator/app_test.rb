require 'abstract_unit'
require 'generator/generator_test_helper'

class AppTest < GeneratorTestCase

  def test_application_skeleton_is_created
    run_generator

    %w(
      app/controllers
      app/helpers
      app/models
      app/views/layouts
      config/environments
      config/initializers
      config/locales
      db
      doc
      lib
      lib/tasks
      log
      public/images
      public/javascripts
      public/stylesheets
      script/performance
      test/fixtures
      test/functional
      test/integration
      test/performance
      test/unit
      vendor
      vendor/plugins
      tmp/sessions
      tmp/sockets
      tmp/cache
      tmp/pids
    ).each{ |path| assert_file path }
  end

  def test_invalid_database_option_raises_an_error
    content = capture(:stderr){ run_generator(["-d", "unknown"]) }
    assert_match /Invalid value for \-\-database option/, content
  end

  def test_dispatchers_are_not_added_by_default
    run_generator
    assert_no_file "config.ru"
    assert_no_file "public/dispatch.cgi"
    assert_no_file "public/dispatch.fcgi"
  end

  def test_dispatchers_are_added_if_required
    run_generator ["--with-dispatchers"]
    assert_file "config.ru"
    assert_file "public/dispatch.cgi"
    assert_file "public/dispatch.fcgi"
  end

  def test_config_database_is_added_by_default
    run_generator
    assert_file "config/database.yml", /sqlite3/
  end

  def test_config_database_is_not_added_if_skip_activerecord_is_given
    run_generator ["--skip-activerecord"]
    assert_no_file "config/database.yml"
  end

  def test_activerecord_is_removed_from_frameworks_if_skip_activerecord_is_given
    run_generator ["--skip-activerecord"]
    assert_file "config/environment.rb", /config\.frameworks \-= \[ :active_record \]/
  end

  def test_prototype_and_test_unit_are_added_by_default
    run_generator
    assert_file "public/javascripts/prototype.js"
    assert_file "test"
  end

  def test_prototype_and_test_unit_are_skipped_if_required
    run_generator ["--skip-prototype", "--skip-testunit"]
    assert_no_file "public/javascripts/prototype.js"
    assert_no_file "test"
  end

  def test_shebang_is_added_to_files
    run_generator ["--ruby", "foo/bar/baz"]

    %w(
      about
      console
      dbconsole
      destroy
      generate
      plugin
      runner
      server
    ).each { |path| assert_file "script/#{path}", /#!foo\/bar\/baz/ }
  end

  def test_rails_is_vendorized_if_freeze_is_supplied
    generator(:freeze => true, :database => "sqlite3").expects(:run).with("rake rails:freeze:edge", false)
    silence(:stdout){ generator.invoke(:all) }
  end

  def test_template_raises_an_error_with_invalid_path
    content = capture(:stderr){ run_generator(["-m", "non/existant/path"]) }
    assert_match /The template \[.*\] could not be loaded/, content
    assert_match /non\/existant\/path/, content
  end

  def test_template_is_executed_when_supplied
    path = "http://gist.github.com/103208.txt"
    template = %{ say "It works!" }
    template.instance_eval "def read; self; end" # Make the string respond to read

    generator(:template => path, :database => "sqlite3").expects(:open).with(path).returns(template)
    assert_match /It works!/, silence(:stdout){ generator.invoke(:all) }
  end

  protected

    def run_generator(args=[])
      silence(:stdout) { Rails::Generators::App.start [destination_root].concat(args) }
    end

    def generator(options={})
      @generator ||= Rails::Generators::App.new([destination_root], options, :root => destination_root)
    end

end