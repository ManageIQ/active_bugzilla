require 'spec_helper'

describe ActiveBugzilla::Service do
  let(:bz) { described_class.new("http://uri.to/bugzilla", "calvin", "hobbes") }

  context "#new" do
    it 'normal case' do
      expect { bz }.to_not raise_error
    end

    it "uses xmlparser's more performant stream parser" do
      expect(bz.send(:xmlrpc_client).send(:parser).class.name).to eq "XMLRPC::XMLParser::XMLStreamParser"
    end

    it "when bugzilla_uri is invalid" do
      expect { described_class.new("lalala", "", "") }.to raise_error(URI::BadURIError)
    end

    it "when username and password are not set" do
      expect { described_class.new("http://uri.to/bugzilla", nil, nil) }.to raise_error(ArgumentError)
    end
  end

  context "#get" do
    it "when no argument is specified" do
      expect { bz.get }.to raise_error(ArgumentError)
    end

    it "when an invalid argument is specified" do
      expect { bz.get("not a Fixnum") }.to raise_error(ArgumentError)
    end

    it "when the specified bug does not exist" do
      output = {}

      allow(::XMLRPC::Client).to receive(:new)
        .and_return(double('xmlrpc_client', :call => output, :set_parser => nil))
      matches = bz.get(94897099)
      expect(matches).to be_kind_of(Array)
      expect(matches).to be_empty
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

      allow(::XMLRPC::Client).to receive(:new)
        .and_return(double('xmlrpc_client', :call => output, :set_parser => nil))
      existing_bz = bz.get("948972").first

      expect(bz.last_command).to include("Bug.get")

      expect(existing_bz["priority"]).to eq("unspecified")
      expect(existing_bz["keywords"]).to eq(["ZStream"])
      expect(existing_bz["cc"]).to eq(["calvin@redhat.com", "hobbes@RedHat.com"])
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
      output        = {}
      error_message = "no BZ with id 94897099 found!"

      allow(::XMLRPC::Client).to receive(:new).and_return(double('xmlrpc_client', :call => output, :set_parser => nil))
      expect { bz.clone(94897099) }.to raise_error ActiveBugzilla::Bug::NotFound, error_message
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
          },
        ]
      }

      expect(bz).to receive(:get).and_return([existing_bz])
      allow(::XMLRPC::Client).to receive(:new)
        .and_return(double('xmlrpc_create', :call => output, :set_parser => nil))
      new_bz_id = bz.clone("948972")

      expect(bz.last_command).to include("Bug.create")

      expect(new_bz_id).to eq(output["id"])
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
          },
        ]
      }

      expect(bz).to receive(:get).and_return([existing_bz])
      allow(::XMLRPC::Client).to receive(:new)
        .and_return(double('xmlrpc_create', :call => output, :set_parser => nil))
      new_bz_id = bz.clone("948972", "assigned_to" => "Ham@NASA.gov", "target_release" => ["2.2.0"])

      expect(bz.last_command).to include("Bug.create")

      expect(new_bz_id).to eq(output["id"])
    end
  end

end
