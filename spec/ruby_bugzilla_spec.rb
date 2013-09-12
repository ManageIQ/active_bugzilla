require 'spec_helper'
require 'tempfile'

class TempCredFile < Tempfile
  def initialize(file)
    f = super
    f.puts("---")
    f.puts(":bugzilla_credentials:")
    f.puts("  :username: My Username")
    f.puts("  :password: My Password")
    f.puts(":bugzilla_options:")
    f.puts("  :bugzilla_uri: MyURI")
    f.puts("  :debug: MyDebug")
    f.flush
  end
end
      
describe RubyBugzilla do
  saved_cmd = RubyBugzilla::CMD
  saved_cookies_file = RubyBugzilla::COOKIES_FILE
  saved_creds_file = RubyBugzilla::CREDS_FILE

  def ignore_warnings(&block)
    begin
      v, $VERBOSE = $VERBOSE, nil
      block.call if block
    ensure
      $VERBOSE = v
    end
  end

  # Run after each tests to reset any faked RubyBugzilla constants.
  after :each do
    ignore_warnings do
      RubyBugzilla::CMD = saved_cmd
      RubyBugzilla::COOKIES_FILE = saved_cookies_file
      RubyBugzilla::CREDS_FILE = saved_creds_file
    end
  end

  context "#logged_in?" do
    it "with an existing bugzilla cookie" do
      Tempfile.open('ruby_bugzilla_spec') do |file|
        ignore_warnings do
          RubyBugzilla::COOKIES_FILE = file.path
        end
        RubyBugzilla.logged_in?.should be true
      end
    end

    it "with no bugzilla cookie" do
      ignore_warnings do
        RubyBugzilla::COOKIES_FILE = '/This/file/does/not/exist'
      end
      RubyBugzilla.logged_in?.should be false
    end
  end

  context "#login!" do

    it "when the bugzilla command is not found" do
      ignore_warnings do
        RubyBugzilla::CMD = '/This/cmd/does/not/exist'
      end
      expect{RubyBugzilla.login!}.to raise_exception
    end

    it "when the bugzilla login command produces output" do
      # Fake the command, cookies file and credentials file.
      TempCredFile.open('ruby_bugzilla_spec') do |file|
        ignore_warnings do
          RubyBugzilla::CREDS_FILE = file.path
          RubyBugzilla::CMD = '/bin/echo'
          RubyBugzilla::COOKIES_FILE = '/This/file/does/not/exist'
        end
        cmd, output = RubyBugzilla.login!
        output.should include("login My Username My Password")
      end
    end

  end

  context "#query" do

    it "when the bugzilla command is not found" do
      ignore_warnings do
        RubyBugzilla::CMD = '/This/cmd/does/not/exist'
      end
      expect{RubyBugzilla.query}.to raise_exception
    end

    it "when no product is specified" do
      ignore_warnings do
        RubyBugzilla::CMD = '/bin/echo'
      end
      expect{RubyBugzilla.query}.to raise_exception
    end

    it "when the bugzilla query command produces output" do
      # Fake the command, cookies file and credentials file.
      TempCredFile.open('ruby_bugzilla_spec') do |file|
        ignore_warnings do
          RubyBugzilla::CMD = '/bin/echo'
        end
        cmd, output = RubyBugzilla.query("MyProduct")
        file.unlink unless file.nil?
        output.should include("query --product=MyProduct")
      end
    end

  end

  context "#credentials" do
    it "when the bugzilla command is not found" do
      ignore_warnings do
        RubyBugzilla::CREDS_FILE = '/This/cmd/does/not/exist'
      end
      expect{RubyBugzilla.credentials}.to raise_exception
    end

    it "when the YAML input is invalid" do
      # Fake the credentials YAML file.
      TempCredFile.open('ruby_bugzilla_spec') do |file|
        ignore_warnings do
          RubyBugzilla::CREDS_FILE = file.path
        end
        un, pw = RubyBugzilla.credentials
        un.should == "My Username"
        pw.should == "My Password"
      end
    end
  end

end

