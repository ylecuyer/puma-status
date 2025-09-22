require 'spec_helper'

require 'puma-status'

describe 'e2e' do
  it 'works' do
    File.delete('/tmp/test_server.state') if File.exist?('/tmp/test_server.state')
    File.delete('/tmp/test_server.sock') if File.exist?('/tmp/test_server.sock')
    File.delete('/tmp/test_server_control.sock') if File.exist?('/tmp/test_server_control.sock')

    # start process test_server.rb
    pid = spawn('ruby spec/test_server.rb')

    # wait until /tmp/test_server.state exists
    until File.exist?('/tmp/test_server.state')
      sleep 0.1
    end

    expect {
      expect {
        run_argv(['/tmp/test_server.state'])
      }.not_to output.to_stderr
    }.to output(/CPU/).to_stdout

    Process.kill('TERM', pid)
    Process.wait(pid)
  end
end
