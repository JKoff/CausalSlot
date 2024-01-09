require "html"
require "http/server"
require "mime/multipart"
require "option_parser"
require "random"
require "sqlite3"

require "./localserver"
require "./remoteserver"

module CausalSlot
  VERSION = "0.1.0"

  localuri = "tcp://127.0.0.1:8080"
  remoteuri = "tcp://127.0.0.1:8081"
  data = Path["."]

  struct DatabasePath
    property data_root

    def initialize(data_root : Path)
      @data_root = data_root
    end

    def main
      @data_root / "main.db"
    end

    def by_address(address)
      @data_root / "#{address}.db"
    end
  end

  OptionParser.parse do |parser|
    parser.banner = "Bitplane"

    parser.on "-v", "--version", "Show version" do
      puts "version 0.1alpha"
      exit
    end
    parser.on "-h", "--help", "Show help" do
      puts parser
      exit
    end
    parser.on "-l URI", "--localuri=URI", "Socket configuration URI for the control plane, e.g. tcp://localhost:8080" do |uri|
      localuri = uri
    end
    parser.on "-r URI", "--remoteuri=URI", "Socket configuration URI for the data plane, e.g. tls://data.jkoff.ca:443?key=private.key&cert=certificate.cert&ca=ca.crt" do |uri|
      remoteuri = uri
    end
    parser.on "-d PATH", "--data=PATH", "Path for storing data files" do |d|
      data = Path[d]
    end
  end

  dbs = DatabasePath.new data

  DB.open "sqlite3://#{dbs.main}" do |db|
    db.exec "create table if not exists addresses (id text, name text)"
  end

  localserv = LocalServer.make dbs
  remoteserv = RemoteServer.make dbs

  localaddr = localserv.bind localuri
  remoteaddr = remoteserv.bind remoteuri
  puts "Storage: #{data.expand}"

  spawn do
    puts "Control plane listening on #{localaddr}"
    localserv.listen
  end

  spawn do
    puts "Data plane listening on #{remoteaddr}"
    remoteserv.listen
  end

  sleep
end
