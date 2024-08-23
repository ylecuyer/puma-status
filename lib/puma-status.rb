require_relative './helpers'
require_relative './core.rb'
require 'parallel'
require 'open3'
require 'net/http'
require 'uri'
require 'openssl'
require 'websocket'

def get_k8s_token_and_server
  kube_config = YAML.load(File.read(File.expand_path("~/.kube/config")))

  current_context = kube_config["current-context"]
  context = kube_config["contexts"].find { |c| c["name"] == current_context }["context"]
  cluster = kube_config["clusters"].find { |c| c["name"] == context["cluster"] }["cluster"]
  user = kube_config["users"].find { |u| u["name"] == context["user"] }["user"]

  stdout_str, stderr_str, status = Open3.capture3(user.dig('exec', 'env').reduce({}) { |a,e| a[e['name']] = e['value']; a }, user.dig('exec', 'command'), *user.dig('exec', 'args'))
  token = JSON.parse(stdout_str)["status"]["token"] 

  return token, cluster['server']
end

def get_pods(token, server)
  uri = URI.parse("#{server}/api/v1/namespaces/dev/pods?labelSelector=container%3Ddwe")
  request = Net::HTTP::Get.new(uri)
  request["Authorization"] = "Bearer #{token}"
  
  req_options = {
    use_ssl: uri.scheme == "https",
    verify_mode: OpenSSL::SSL::VERIFY_NONE,
  }
  
  response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
    http.request(request)
  end

  pods = JSON.parse(response.body)["items"].map { |pod| pod["metadata"]["name"] }
end

def get_stats_for_pod(token, server, pod, state_file_path)
  uri = URI.parse("#{server}/api/v1/namespaces/dev/pods/#{pod}/exec")
  uri.scheme = 'wss'
  uri.port = 443
  
  commands = <<~BASH.split("\n")
    export $(awk -F": " '/:/ {print toupper($1)"="$2}' #{state_file_path})
    curl -s --unix-socket $(echo "$CONTROL_URL" | sed 's#^unix://##') http://localhost/stats?token=$CONTROL_AUTH_TOKEN
  BASH
  bash_command = ["/bin/bash", "-lc", commands.join(" && ")].map { URI.encode_www_form_component(_1) }.join("&command=")

  socket = TCPSocket.new(uri.host, uri.port)
  ssl_context = OpenSSL::SSL::SSLContext.new
  ssl_context.verify_mode = OpenSSL::SSL::VERIFY_NONE
  ssl_socket = OpenSSL::SSL::SSLSocket.new(socket, ssl_context)
  uri.query = "command=#{bash_command}&stderr=true&stdin=false&stdout=true&tty=false"

  handshake = ::WebSocket::Handshake::Client.new :url => uri.to_s, headers: { "Authorization" => "Bearer #{token}", "Sec-WebSocket-Protocol" => "v4.channel.k8s.io" }
  frame = ::WebSocket::Frame::Incoming::Client.new

  ssl_socket.connect
  ssl_socket.write(handshake.to_s)

  until handshake.finished?
    recv = ssl_socket.gets
    handshake << recv
  end

  while recv = ssl_socket.gets
    frame << recv
  end

  stats = nil
  while d = frame.next
    case d.type
    when :binary
      if d.to_s[0] == "\u0001"
        stats = d.to_s[1..-1]
      end
    when :close
      break
    end
  end

  ssl_socket.close
  socket.close

  return Stats.new(JSON.parse(stats), origin: pod)
end

def run
  debug "puma-status"

  if ARGV.count < 1
    puts "Call with:"
    puts "\tpuma-status path/to/puma.state"
    exit -1
  end

  errors = []

  token, server = get_k8s_token_and_server
  pods = get_pods(token, server)

  outputs = Parallel.map(ARGV, in_threads: ARGV.count) do |state_file_path|
    begin
      debug "State file: #{state_file_path}"

      if true
        pods.map do |pod|
          stats = get_stats_for_pod(token, server, pod, state_file_path)
          format_stats(stats)
        end.join("\n")
      else
        format_stats(get_stats(state_file_path))
      end
    rescue Errno::ENOENT => e
      if e.message =~ /#{state_file_path}/
        errors << "#{yellow(state_file_path)} doesn't exist"
      elsif e.message =~ /connect\(2\) for [^\/]/
        errors << "#{yellow("Relative Unix socket")}: the Unix socket of the control app has a relative path. Please, ensure you are running from the same folder as puma."
      else
        errors << "#{red(state_file_path)} an unhandled error occured: #{e.inspect}"
      end
      nil
    rescue Errno::EISDIR => e
      if e.message =~ /#{state_file_path}/
        errors << "#{yellow(state_file_path)} isn't a state file"
      else
        errors << "#{red(state_file_path)} an unhandled error occured: #{e.inspect}"
      end
      nil
    rescue => e
      errors << "#{red(state_file_path)} an unhandled error occured: #{e.inspect}"
      nil
    end
  end

  outputs.compact.each { |output| puts output }

  if errors.any?
    puts ""
    errors.each { |error| puts error }
  end
end
