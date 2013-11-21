require 'spec_helper'

describe RubyBugzilla do
  saved_cmd = RubyBugzilla::CMD
  saved_cookies_file = RubyBugzilla::COOKIES_FILE

  def ignore_warnings(&block)
    begin
      v, $VERBOSE = $VERBOSE, nil
      block.call if block
    ensure
      $VERBOSE = v
    end
  end

  let(:bz) { RubyBugzilla.new("calvin", "hobbes") }

  before do
    # Assume most tests have bugzilla installed and logged in by faking with
    #   valid files
    ignore_warnings do
      RubyBugzilla::CMD = "/bin/echo"
      RubyBugzilla::COOKIES_FILE = "/bin/echo"
    end
  end

  after do
    # Reset any faked RubyBugzilla constants.
    ignore_warnings do
      RubyBugzilla::CMD = saved_cmd
      RubyBugzilla::COOKIES_FILE = saved_cookies_file
    end
  end

  context ".logged_in?" do
    it "with an existing bugzilla cookie" do
      RubyBugzilla.logged_in?.should be_true
    end

    it "with no bugzilla cookie" do
      ignore_warnings do
        RubyBugzilla::COOKIES_FILE = '/This/file/does/not/exist'
      end
      RubyBugzilla.logged_in?.should be_false
    end
  end

  context "#new" do
    it 'normal case' do
      expect { bz }.to_not raise_error
    end

    it "when the bugzilla command is not found" do
      ignore_warnings do
        RubyBugzilla::CMD = '/This/cmd/does/not/exist'
      end
      expect { bz }.to raise_error
    end

    it "when username and password are not set" do
      expect { RubyBugzilla.new(nil, nil) }.to raise_error(ArgumentError)
    end
  end

  context "#login" do
    it "when already logged in" do
      output = bz.login

      bz.last_command.should be_nil
      output.should include("Already Logged In")
    end

    it "when not already logged in" do
      ignore_warnings do
        RubyBugzilla::COOKIES_FILE = '/This/file/does/not/exist'
      end
      bz.login

      bz.last_command.should include("login")
    end
  end

  context "#query" do
    it "when no product is specified" do
      expect { bz.query }.to raise_error(ArgumentError)
    end

    it "when the bugzilla query command produces output" do
      output = bz.query('CloudForms Management Engine', nil,
        'NEW, ASSIGNED, POST, MODIFIED, ON_DEV, ON_QA, VERIFIED, RELEASE_PENDING',
        'BZ_ID: %{id} STATUS: %{bug_status} SUMMARY: %{summary}'
      )

      bz.last_command.should include("query")
      output.should include("BZ_ID:")
      output.should include("STATUS:")
      output.should include("SUMMARY:")
    end
  end

  context "#modify" do
    it "when no arguments are specified" do
      expect { bz.modify }.to raise_error(ArgumentError)
    end

    it "when no bugids are are specified" do
      expect { bz.modify("", :status => "POST") }.to raise_error(ArgumentError)
    end

    it "when no options are specified" do
      expect { bz.modify(9, {}) }.to raise_error(ArgumentError)
    end

    it "when the bugzilla modify command succeeds for one option and multiple BZs" do
      bz.modify(["948970", "948971", "948972", "948973"], :status => "RELEASE_PENDING")

      bz.last_command.should include("modify")
      bz.last_command.should include("--status=\"RELEASE_PENDING\"")
      bz.last_command.should include("948970")
      bz.last_command.should include("948971")
      bz.last_command.should include("948972")
      bz.last_command.should include("948973")
    end

    it "when the bugzilla modify command succeeds for multiple options and a Array BZ" do
      bz.modify(["948972"], :status => "POST", :comment => "Fixed in shabla")

      bz.last_command.should include("modify")
      bz.last_command.should include("--status=\"POST\"")
      bz.last_command.should include("948972")
      bz.last_command.should include("Fixed in shabla")
    end

    it "when the bugzilla modify command succeeds for a Fixnum BZ" do
      bz.modify(948972, :status => "POST")

      bz.last_command.should include("modify")
      bz.last_command.should include("--status=\"POST\"")
      bz.last_command.should include("948972")
    end

    it "when the bugzilla modify command succeeds for a String BZ" do
      bz.modify("948972", :status => "POST")

      bz.last_command.should include("modify")
      bz.last_command.should include("--status=\"POST\"")
      bz.last_command.should include("948972")
    end
  end
end
