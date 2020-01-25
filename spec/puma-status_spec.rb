require 'spec_helper'

require './lib/puma-status'

RSpec::Matchers.define_negated_matcher :not_raise_error, :raise_error

describe 'Puma Status' do
  before(:each) do
    allow(Parallel).to receive(:map) do |state_files, options, &block|
      expect(options[:in_threads]).to eq(state_files.count)
      state_files.map(&block)
    end
  end

  it 'exits with an error if no state file' do
    ARGV.replace []
    expect {
      run
    }.to output.to_stdout .and raise_error(SystemExit) do |error|
      expect(error.status).to eq(-1)
    end
  end

  it 'works with one state file' do
    ARGV.replace ['./tmp/puma.state']
    allow_any_instance_of(Object).to receive(:get_stats).once { true }
    allow_any_instance_of(Object).to receive(:format_stats).once { true }
    expect {
      run
    }.to output.to_stdout
  end

  it 'works with multiple state file' do
    ARGV.replace ['./tmp/puma.state', './tmp/puma2.state']
    allow_any_instance_of(Object).to receive(:get_stats).twice { true }
    allow_any_instance_of(Object).to receive(:format_stats).twice { true }
    expect {
      run
    }.to output.to_stdout
  end
end
