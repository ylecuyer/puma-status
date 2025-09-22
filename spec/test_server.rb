require 'puma'

puma_version = Puma::Const::PUMA_VERSION
ruby_version = RUBY_VERSION

# Rack app
app = proc { |env| [200, { 'Content-Type' => 'text/plain' }, ["Test server: puma: #{puma_version} ruby: #{ruby_version}\n"]] }

Puma::Launcher.new(
  Puma::Configuration.new do |user_config|
    user_config.bind 'unix:///tmp/test_server.sock'
    user_config.workers 1
    user_config.threads 1, 1
    user_config.app app
    user_config.activate_control_app 'unix:///tmp/test_server_control.sock', { auth_token: 'secret_token' }
    user_config.state_path '/tmp/test_server.state'
    user_config.stdout_redirect '/tmp/test_server.log', '/tmp/test_server.err', true
  end,
  {
    log_writer: Puma::LogWriter.null,
  }
).run

# To run this server, execute:
#  ruby test_server.rb
#  Then, you can test it with:
#  curl --unix-socket /tmp/test_server.sock http://localhost/
#  You should see the output with Puma and Ruby versions.
#  To stop the server, simply interrupt the process (Ctrl+C).
