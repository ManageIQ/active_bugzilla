require 'spec_helper'

describe RubyBugzilla::Service do
  let(:bz) { described_class.new("http://uri.to/bugzilla", "calvin", "hobbes") }

  before do
    # Assume most tests have bugzilla installed and logged in by faking with
    #   valid files
    stub_const("#{described_class.name}::CMD", "/bin/echo")
    stub_const("#{described_class.name}::COOKIES_FILE", File.expand_path("data/cookies_file", File.dirname(__FILE__)))
  end

  context "#new" do
    it 'normal case' do
      expect { bz }.to_not raise_error
    end

    it "when the bugzilla command is not found" do
      stub_const("#{described_class.name}::CMD", "/This/cmd/does/not/exist")
      expect { bz }.to raise_error
    end

    it "when bugzilla_uri is invalid" do
      expect { described_class.new("lalala", "", "") }.to raise_error(URI::BadURIError)
    end

    it "when username and password are not set" do
      expect { described_class.new("http://uri.to/bugzilla", nil, nil) }.to raise_error(ArgumentError)
    end
  end

  context "#login" do
    it "when already logged in" do
      bz.login
      bz.last_command.should include("login")
    end

    it "when not already logged in" do
      stub_const("#{described_class.name}::COOKIES_FILE", "/This/file/does/not/exist")
      bz.login
      bz.last_command.should include("login")
    end
  end

  context "#query" do
    it "when no arguments are specified" do
      expect { bz.query }.to raise_error(ArgumentError)
    end

    it "when the bugzilla query command produces output" do
      output = bz.query(
        :product      => 'CloudForms Management Engine',
        :bug_status   => 'NEW, ASSIGNED, POST, MODIFIED, ON_DEV, ON_QA, VERIFIED, RELEASE_PENDING',
        :outputformat => 'BZ_ID: %{id} STATUS: %{bug_status} SUMMARY: %{summary}'
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

    it "when invalid bugids are are specified" do
      expect { bz.modify("", :status => "POST") }.to raise_error(ArgumentError)
    end

    it "when no options are specified" do
      expect { bz.modify(9, {}) }.to raise_error(ArgumentError)
    end

    it "when the bugzilla modify command succeeds for one option and multiple BZs" do
      bz.modify(["948970", "948971", "948972", "948973"], :status => "RELEASE_PENDING")

      bz.last_command.should include("modify")
      bz.last_command.should include("--status=RELEASE_PENDING")
      bz.last_command.should include("948970")
      bz.last_command.should include("948971")
      bz.last_command.should include("948972")
      bz.last_command.should include("948973")
    end

    it "when the bugzilla modify command succeeds for multiple options and a Array BZ" do
      bz.modify(["948972"], :status => "POST", :comment => "Fixed in shabla")

      bz.last_command.should include("modify")
      bz.last_command.should include("--status=POST")
      bz.last_command.should include("948972")
      bz.last_command.should include("Fixed\\ in\\ shabla")
    end

    it "when the bugzilla modify command succeeds for a Fixnum BZ" do
      bz.modify(948972, :status => "POST")

      bz.last_command.should include("modify")
      bz.last_command.should include("--status=POST")
      bz.last_command.should include("948972")
    end

    it "when the bugzilla modify command succeeds for a String BZ" do
      bz.modify("948972", :status => "POST")

      bz.last_command.should include("modify")
      bz.last_command.should include("--status=POST")
      bz.last_command.should include("948972")
    end
  end

  context "#xmlrpc_bug_query" do
    it "when no argument is specified" do
      expect { bz.xmlrpc_bug_query }.to raise_error(ArgumentError)
    end

    it "when an invalid argument is specified" do
      expect { bz.xmlrpc_bug_query("not a Fixnum") }.to raise_error(ArgumentError)
    end

    it "when the specified bug does not exist" do
      output = {}

      allow(::XMLRPC::Client).to receive(:new).and_return(double('xmlrpc_client', :call => output))
      matches = bz.xmlrpc_bug_query(94897099)
      matches.should be_kind_of(Array)
      matches.should be_empty
    end

    it "when producing valid output" do
      output = {
        'bugs' => [
          {
            "priority" => "unspecified",
            "keywords" => ["ZStream"],
            "cc"       => ["calvin@redhat.com", "hobbes@RedHat.com"],
          },
        ]
      }

      allow(::XMLRPC::Client).to receive(:new).and_return(double('xmlrpc_client', :call => output))
      existing_bz = bz.xmlrpc_bug_query("948972").first

      bz.last_command.should include("Bug.get")

      existing_bz["priority"].should == "unspecified"
      existing_bz["keywords"].should == ["ZStream"]
      existing_bz["cc"].should       == ["calvin@redhat.com", "hobbes@RedHat.com"]

    end
  end

  context "#clone" do
    it "when no argument is specified" do
      expect { bz.clone }.to raise_error(ArgumentError)
    end

    it "when an invalid argument is specified" do
      expect { bz.clone("not a Fixnum") }.to raise_error(ArgumentError)
    end

    it "when the specified bug to clone does not exist" do
      output = {}

      allow(::XMLRPC::Client).to receive(:new).and_return(double('xmlrpc_client', :call => output))
      expect { bz.clone(94897099) }.to raise_error
    end

    it "when producing valid output" do
      output = {"id" => 948992}
      existing_bz = {
        "description"    => "Description of problem:\n\nIt's Broken",
        "priority"       => "unspecified",
        "assigned_to"    => "calvin@redhat.com",
        "target_release" => ["---"],
        "keywords"       => ["ZStream"],
        "cc"             => ["calvin@redhat.com", "hobbes@RedHat.com"],
        "comments"       => [
          {
            "is_private"    => false,
            "count"         => 0,
            "time"          => XMLRPC::DateTime.new(1969, 7, 20, 16, 18, 30),
            "bug_id"        => 948970,
            "author"        => "Calvin@redhat.com",
            "text"          => "It's Broken and impossible to reproduce",
            "creation_time" => XMLRPC::DateTime.new(1969, 7, 20, 16, 18, 30),
            "id"            => 5777871,
            "creator_id"    => 349490
          },
          {
            "is_private"    => false,
            "count"         => 1,
            "time"          => XMLRPC::DateTime.new(1970, 11, 10, 16, 18, 30),
            "bug_id"        => 948970,
            "author"        => "Hobbes@redhat.com",
            "text"          => "Fix Me Now!",
            "creation_time" => XMLRPC::DateTime.new(1972, 2, 14, 0, 0, 0),
            "id"            => 5782170,
            "creator_id"    => 349490
          },]
      }

      described_class.any_instance.stub(:xmlrpc_bug_query).and_return([existing_bz])
      allow(::XMLRPC::Client).to receive(:new).and_return(double('xmlrpc_create', :call => output))
      new_bz_id = bz.clone("948972")

      bz.last_command.should include("Bug.create")

      new_bz_id.should == output["id"]
    end

    it "when providing override values" do
      output = {"id" => 948992}
      existing_bz = {
        "description"    => "Description of problem:\n\nIt's Broken",
        "priority"       => "unspecified", 
        "assigned_to"    => "calvin@redhat.com",
        "target_release" => ["---"], 
        "keywords"       => ["ZStream"],
        "cc"             => ["calvin@redhat.com", "hobbes@RedHat.com"],
        "comments"       => [
          {
            "is_private"    => false,
            "count"         => 0,
            "time"          => XMLRPC::DateTime.new(1969, 7, 20, 16, 18, 30),
            "bug_id"        => 948970,
            "author"        => "Buzz.Aldrin@redhat.com",
            "text"          => "It's Broken and impossible to reproduce",
            "creation_time" => XMLRPC::DateTime.new(1969, 7, 20, 16, 18, 30),
            "id"            => 5777871,
            "creator_id"    => 349490
          },
          {
            "is_private"    => false,
            "count"         => 1,
            "time"          => XMLRPC::DateTime.new(1970, 11, 10, 16, 18, 30),
            "bug_id"        => 948970,
            "author"        => "Neil.Armstrong@redhat.com",
            "text"          => "Fix Me Now!",
            "creation_time" => XMLRPC::DateTime.new(1972, 2, 14, 0, 0, 0),
            "id"            => 5782170,
            "creator_id"    => 349490
          },]
      }

      described_class.any_instance.stub(:xmlrpc_bug_query).and_return([existing_bz])
      allow(::XMLRPC::Client).to receive(:new).and_return(double('xmlrpc_create', :call => output))
      new_bz_id = bz.clone("948972", {"assigned_to" => "Ham@NASA.gov", "target_release" => ["2.2.0"],} )

      bz.last_command.should include("Bug.create")

      new_bz_id.should == output["id"]
    end
  end
end
