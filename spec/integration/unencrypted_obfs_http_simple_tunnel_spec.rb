require "spec_helper"
require 'evented-spec'
require 'em-http'

RSpec.describe "unencrypted tunnel proxy server" do
  include EventedSpec::SpecHelper
  it "should be act like a proxy server" do
    em do
      stack3 = ShadowsocksRuby::Protocols::ProtocolStack.new([
          ["shadowsocks", {}],
          ["http_simple", {}]
      ], "aes-256-cfb", "secret")
      stack4 = ShadowsocksRuby::Protocols::ProtocolStack.new([
          ["plain", {}]
      ], "aes-256-cfb", "secret")
      server_args = [stack3, {}, stack4, {} ]
      EventMachine.start_server '127.0.0.1', 8388, ShadowsocksRuby::Connections::TCP::LocalBackendConnection, *server_args


      stack1 = ShadowsocksRuby::Protocols::ProtocolStack.new([
          ["socks5", {}]
      ], "aes-256-cfb", "secret")
      stack2 = ShadowsocksRuby::Protocols::ProtocolStack.new([
          ["shadowsocks", {}],
          ["http_simple", {:host => '127.0.0.1', :port => 8388}]
      ], "aes-256-cfb", "secret")
      local_args = [stack1, {:host => '127.0.0.1', :port => 8388}, stack2, {} ]
      EventMachine.start_server '127.0.0.1', 10800, ShadowsocksRuby::Connections::TCP::ClientConnection, *local_args


      connection_opts = {:proxy => {:host => '127.0.0.1', :port => 10800, :type => :socks5 }}

      http = EventMachine::HttpRequest.new('http://example.com/', connection_opts).get
      http.callback {
        expect(http.response_header.status).to eq(200)
        done
      }
    end      
  end
end
