require File.dirname(__FILE__) + '/../../spec_helper'
require 'aws/ie'
require 'yaml'

describe AWS::Import::Job do

  let(:manifest) do
    File.read(File.join(File.dirname(__FILE__), "../../fixtures/manifest.yml"))
  end

  let(:client) do
    AWS::IE::Client.new
  end

  let(:response) do
    File.read(File.join(
                        File.dirname(__FILE__),
                        "../../fixtures/#{response_file_name}"))
  end

  describe "in general" do

    it "should have manifest" do
      job = described_class.new
      job.manifest.should be_nil
      job.manifest = "manifest content"
      job.manifest.should == "manifest content"
    end

    it "should get the parameters from constructor" do
      job = described_class.new(:manifest => "manifest content")
      job.manifest.should == "manifest content"
    end

  end

  describe "when find a job by id" do

    let(:response_file_name) do
      "get_status_response_successfull.xml"
    end

    let(:params) do
      {
        "JobType" => "Import",
        "Operation" => "GetStatus",
        "JobId" => "ABC-123"
      }
    end

    let(:job) { AWS::Import::Job.new }

    before do
      client
      AWS::IE::Client.stub!(:new).and_return(client)
      client.stub!(:post).with(params).and_return(response)
    end

    context "but job does not exist" do

      let(:response_file_name) do
        "get_status_response_failed.xml"
      end

      it "should raise exception when job is not found" do
        job
        lambda { AWS::Import::Job.find("ABC-123") }.
          should raise_error(AWS::Import::Job::JobNotFound)
      end

    end

    it "should send JobStatus API request" do
      client
      AWS::IE::Client.should_receive(:new).and_return(client)
      client.should_receive(:post).with(params).and_return(response)
      AWS::Import::Job.find("ABC-123")
    end

    it "should create Job instance and have all attributes set" do
      job
      AWS::Import::Job.should_receive(:new).and_return(job)
      AWS::Import::Job.find("ABC-123")
      job.manifest.should == manifest
      job.id.should == "ABC-123"
      job.status[:code].should == "Pending"
      job.status[:message].should == "The specified job has not started."
      job.signature.should == "D6j+YqwmWiVXQzuy5Bu0lxehI3E="
    end

  end

  describe "when is being canceled" do

    let(:params) do
      {
        "JobType" => "Import",
        "Operation" => "CancelJob",
        "JobId" => "ABC-123"
      }
    end

    context "successfully" do

      let(:response_file_name) { "cancel_job_response_successfull.xml" }

      it "should send cancel request and get successfull response" do
        client
        AWS::IE::Client.should_receive(:new).and_return(client)
        client.should_receive(:post).with(params).and_return(response)
        described_class.cancel("ABC-123").should be_true
      end

    end

    context "failed" do

      let(:response_file_name) { "cancel_job_response_failed.xml" }

      it "should send cancel request and get failed response" do
        client
        AWS::IE::Client.should_receive(:new).and_return(client)
        client.should_receive(:post).with(params).and_return(response)
        described_class.cancel("ABC-123").should be_false
      end

    end

  end

  describe "when is being created" do

    let(:response_file_name) { "create_job_response.xml" }

    let(:manifest) do
      { }
    end

    let(:params) do
      {
        "JobType" => "Import",
        "Operation" => "CreateJob",
        "Manifest" => manifest.to_yaml
      }
    end

    before do
      client
      AWS::IE::Client.stub!(:new).and_return(client)
      client.stub!(:post).and_return(response)
    end

    it "should create AWS::IE::Client instance" do
      AWS::IE::Client.should_receive(:new).and_return(client)
      described_class.create(:manifest => manifest.to_yaml).
        should be_instance_of(described_class)
    end

    it "should send API request" do
      client.should_receive(:post).with(params).and_return(response)
      described_class.create(:manifest => manifest.to_yaml).
        should be_instance_of(described_class)
    end

    it "should get the Job ID from response" do
      job = described_class.create(:manifest => manifest.to_yaml)
      job.id.should == "45HFS-VALIDATE-ONLY"
    end

    it "should have the signature" do
      job = described_class.create(:manifest => manifest.to_yaml)
      job.signature.should == "/dxgK27c8++SFiZLLaIvHt4Oy4k="
    end

    describe "and error occures" do

      it "should have the error code and description"
      it "should not get the Job ID"

    end

  end

end
