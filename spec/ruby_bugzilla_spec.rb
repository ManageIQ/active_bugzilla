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
      RubyBugzilla.username = nil
      RubyBugzilla.password = nil
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
      expect { RubyBugzilla.login! }.to raise_exception
    end

    it "when the bugzilla login command produces output" do
      # Fake the command and cookies file.
      ignore_warnings do
        RubyBugzilla::CMD = '/bin/echo'
        RubyBugzilla::COOKIES_FILE = '/This/file/does/not/exist'
      end
      cmd, output = RubyBugzilla.login!("My Username", "My Password")
      output.should include("login My Username My Password")
    end

    it "when the bugzilla login command produces output with arguments" do
      # Fake the command and cookies file.
      ignore_warnings do
        RubyBugzilla::CMD = '/bin/echo'
        RubyBugzilla::COOKIES_FILE = '/This/file/does/not/exist'
      end
      cmd, output = RubyBugzilla.login!("calvin", "hobbes")
      output.should include("login calvin hobbes")
    end
  end

  context "#query" do
    it "when the bugzilla command is not found" do
      ignore_warnings do
        RubyBugzilla::CMD = '/This/cmd/does/not/exist'
      end
      expect { RubyBugzilla.query }.to raise_exception
    end

    it "when no product is specified" do
      ignore_warnings do
        RubyBugzilla::CMD = '/bin/echo'
      end
      expect { RubyBugzilla.query }.to raise_error(ArgumentError)
    end

    it "when the bugzilla query command produces output" do
      # Fake the command and cookies file.
      ignore_warnings do
        RubyBugzilla::CMD = '/bin/echo'
        RubyBugzilla::COOKIES_FILE = '/This/file/does/not/exist'
      end

      cmd, output = RubyBugzilla.login!("calvin", "hobbes")
      cmd, output = RubyBugzilla.query('CloudForms Management Engine',
        flag = '',
        bug_status = 'NEW, ASSIGNED, POST, MODIFIED, ON_DEV, ON_QA, VERIFIED, RELEASE_PENDING',
        output_format = 'BZ_ID: %{id} STATUS: %{bug_status} SUMMARY: %{summary}')

      cmd.should include("query")
      output.should include("BZ_ID:")
      output.should include("STATUS:")
      output.should include("SUMMARY:")
    end
  end

  context "#modify" do
    it "when the bugzilla command is not found" do
      ignore_warnings do
        RubyBugzilla::CMD = '/This/cmd/does/not/exist'
      end
      expect { RubyBugzilla.modify }.to raise_exception
    end

    it "when no arguments are specified" do
      ignore_warnings do
        RubyBugzilla::CMD = '/bin/echo'
      end
      expect { RubyBugzilla.modify }.to raise_error(ArgumentError)
    end

    it "when no bugids are are specified" do
      ignore_warnings do
        RubyBugzilla::CMD = '/bin/echo'
      end
      expect { RubyBugzilla.modify("", :status => "POST") }.to raise_error(ArgumentError)
    end

    it "when no options are specified" do
      ignore_warnings do
        RubyBugzilla::CMD = '/bin/echo'
      end
      expect { RubyBugzilla.modify(9, {}) }.to raise_error(ArgumentError)
    end

    it "when the bugzilla modify command succeeds for one option and multiple BZs" do
      # Fake the command and cookies file.
      ignore_warnings do
        RubyBugzilla::CMD = '/bin/echo'
        RubyBugzilla::COOKIES_FILE = '/This/file/does/not/exist'
      end

      cmd, output = RubyBugzilla.login!("calvin", "hobbes")
      cmd = RubyBugzilla.modify(["948970", "948971", "948972", "948973"],
        :status => "RELEASE_PENDING")

      cmd.should include("modify")
      cmd.should include("--status=\"RELEASE_PENDING\"")
      cmd.should include("948970")
      cmd.should include("948971")
      cmd.should include("948972")
      cmd.should include("948973")
    end

    it "when the bugzilla modify command succeeds for multiple options and a Array BZ" do
      # Fake the command and cookies file.
      ignore_warnings do
        RubyBugzilla::CMD = '/bin/echo'
        RubyBugzilla::COOKIES_FILE = '/This/file/does/not/exist'
      end

      cmd, output = RubyBugzilla.login!("calvin", "hobbes")
      cmd = RubyBugzilla.modify(bugids = ["948972"],
        options = { :status => "POST", :comment => "Fixed in shabla" } )

      cmd.should include("modify")
      cmd.should include("--status=\"POST\"")
      cmd.should include("948972")
      cmd.should include("Fixed in shabla")
    end

    it "when the bugzilla modify command succeeds for a Fixnum BZ" do
      # Fake the command and cookies file.
      ignore_warnings do
        RubyBugzilla::CMD = '/bin/echo'
        RubyBugzilla::COOKIES_FILE = '/This/file/does/not/exist'
      end

      cmd, output = RubyBugzilla.login!("calvin", "hobbes")
      cmd = RubyBugzilla.modify(948972, :status => "POST")

      cmd.should include("modify")
      cmd.should include("--status=\"POST\"")
      cmd.should include("948972")
    end

    it "when the bugzilla modify command succeeds for a String BZ" do
      # Fake the command and cookies file.
      ignore_warnings do
        RubyBugzilla::CMD = '/bin/echo'
        RubyBugzilla::COOKIES_FILE = '/This/file/does/not/exist'
      end

      cmd, output = RubyBugzilla.login!("calvin", "hobbes")
      cmd = RubyBugzilla.modify("948972", :status => "POST")

      cmd.should include("modify")
      cmd.should include("--status=\"POST\"")
      cmd.should include("948972")
    end
  end

  context "#credentials_from_file" do
    it "when the YAML input file is not found" do
      ignore_warnings do
        RubyBugzilla::CREDS_FILE = '/This/cmd/does/not/exist'
      end
      un, pw = RubyBugzilla.credentials_from_file
      un.should == nil
      pw.should == nil
    end

    it "when the YAML input is valid" do
      # Fake the credentials YAML file.
      TempCredFile.open('ruby_bugzilla_spec') do |file|
        ignore_warnings do
          RubyBugzilla::CREDS_FILE = file.path
        end
        un, pw = RubyBugzilla.credentials_from_file
        un.should == "My Username"
        pw.should == "My Password"
      end
    end
  end

  context "#credentials" do
    it "with no arguments and when the YAML input file is not found" do
      ignore_warnings do
        RubyBugzilla::CREDS_FILE = '/This/cmd/does/not/exist'
      end
      un, pw = RubyBugzilla.credentials
      un.should == nil
      pw.should == nil
    end

    it "with no arguments and when the YAML input is valid" do
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

    it "with arguments and when the YAML input file is not found" do
      ignore_warnings do
        RubyBugzilla::CREDS_FILE = '/This/cmd/does/not/exist'
      end
      un, pw = RubyBugzilla.credentials("test_un", "test_pw")
      un.should == "test_un"
      pw.should == "test_pw"
    end

    it "with arguments and valid YAML input, favor arguments" do
      # Fake the credentials YAML file.
      TempCredFile.open('ruby_bugzilla_spec') do |file|
        ignore_warnings do
          RubyBugzilla::CREDS_FILE = file.path
        end
        un, pw = RubyBugzilla.credentials("test_un", "test_pw")
        un.should == "test_un"
        pw.should == "test_pw"
      end
    end

    it "with password argument and valid YAML input, favor argument" do
      # Fake the credentials YAML file.
      TempCredFile.open('ruby_bugzilla_spec') do |file|
        ignore_warnings do
          RubyBugzilla::CREDS_FILE = file.path
        end
        un, pw = RubyBugzilla.credentials(nil, "test_pw")
        un.should == "My Username"
        pw.should == "test_pw"
      end
    end

    it "with username argument and valid YAML input, favor argument" do
      # Fake the credentials YAML file.
      TempCredFile.open('ruby_bugzilla_spec') do |file|
        ignore_warnings do
          RubyBugzilla::CREDS_FILE = file.path
        end
        un, pw = RubyBugzilla.credentials("test_un")
        un.should == "test_un"
        pw.should == "My Password"
      end
    end
  end

  context "#options" do
    it "when the YAML input is valid" do
      # Fake the credentials YAML file.
      TempCredFile.open('ruby_bugzilla_spec') do |file|
        ignore_warnings do
          RubyBugzilla::CREDS_FILE = file.path
        end
        uri, debug = RubyBugzilla.options
        uri.should == "MyURI"
        debug.should == "MyDebug"
      end
    end
    it "when the YAML input is is not found" do
      ignore_warnings do
        RubyBugzilla::CREDS_FILE = '/This/cmd/does/not/exist'
      end
      uri, debug = RubyBugzilla.options
      uri.should == "https://bugzilla.redhat.com/"
      debug.should == false
    end
  end
end
