require "http/server"

require "./protocol"

module RemoteServer
  def self.make(dbs)
    HTTP::Server.new do |context|
      if (address = context.request.path.lchop? "/address/") && context.request.method == "GET"
        context.response.headers["Access-Control-Allow-Origin"] = "*"
        context.response.content_type = "text/plain"

        proto = ReadProtocol.new context.response
        proto.start
        DB.open "sqlite3://#{dbs.by_address address}" do |db|
          db.query "select vsn, data from writes" do |rs|
            rs.each do
              vsn = rs.read(Int64).to_u64
              dat = rs.read(Slice(UInt8))
              proto.send vsn, dat
            end
          end
        end
      elsif (address = context.request.path.lchop? "/address/") && context.request.method == "POST"
        context.response.headers["Access-Control-Allow-Origin"] = "*"
        context.response.content_type = "text/plain"
        body = context.request.body
        if body.nil?
          context.response.respond_with_status 400
          next
        end

        proto = WriteProtocol.new IO::Stapled.new(body, context.response)
        proto.start
        versions = proto.versions
        payload = proto.payload

        newvsn = nil
        DB.open "sqlite3://#{dbs.by_address address}" do |db|
          res = db.exec "insert into writes (data) values (?)", payload
          newvsn = res.last_insert_id

          versions.each do |version|
            db.exec "delete from writes where vsn = ?", version.to_i64
          end
        end
        if newvsn.nil?
          context.response.respond_with_status 400
          next
        end

        proto.send newvsn.to_u64
      else
        context.response.respond_with_status 404
      end
    end
  end
end