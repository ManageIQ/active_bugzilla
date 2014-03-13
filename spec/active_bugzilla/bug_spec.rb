require 'spec_helper'

describe ActiveBugzilla::Bug do
  context "#new" do
    before(:each) do
      @service_mapping = {
        # Bug     => XMLRPC
        :severity => :severity_xmlrpc,
        :priority => :priority_xmlrpc,
      }
      @service = double('service')
      ActiveBugzilla::Base.service = @service
      described_class.stub(:generate_xmlrpc_map).and_return(@service_mapping)
      described_class.stub(:xmlrpc_timestamps).and_return([])
      @id  = 123
      @bug = described_class.new(:id => @id)
    end

    it "attribute_names" do
      raw_keys = @service_mapping.values
      raw_data = {}
      raw_keys.each { |k| raw_data[k.to_s] = 'foo' }
      @bug.stub(:raw_data).and_return(raw_data)
      expect(@bug.attribute_names).to eq(@service_mapping.keys.sort_by { |key| key.to_s })
    end

    it "severity" do
      severity = 'foo'
      raw_data = {'severity_xmlrpc' => severity}
      @bug.stub(:raw_data).and_return(raw_data)
      expect(@bug.severity).to eq(severity)
    end

    it "comments" do
      comments_hash = [{'id' => 1}]
      raw_data = {'comments' => comments_hash}
      @bug.stub(:raw_data).and_return(raw_data)
      comments = @bug.comments
      expect(comments).to be_kind_of(Array)
      expect(comments.count).to eq(1)
      expect(comments.first).to be_kind_of(ActiveBugzilla::Comment)
    end

  end
end
