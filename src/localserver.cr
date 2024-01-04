require "http/server"

module LocalServer
  def self.make(dbs)
    HTTP::Server.new do |context|
      if context.request.path == "/"
        context.response.content_type = "text/html"
        context.response.print "
          <h2>Add address</h2>
          <form action=\"/add\" method=\"post\">
            <input type='text' name='name' placeholder='name'>
            <input type='submit' value='Add'>
          </form>
        "
        context.response.print "
          <h2>Addresses</h2>
          <table>
        "
        DB.open "sqlite3://#{dbs.main}" do |db|
          db.query "select id, name from addresses" do |rs|
            context.response.print "
              <tr>
                <th>#{HTML.escape(rs.column_name(0))}</th>
                <th>#{HTML.escape(rs.column_name(1))}</th>
                <th>Size on disk</th>
              </tr>
            "
            rs.each do
              address = rs.read(String)
              size = File.size dbs.by_address address
              context.response.print "
                <tr>
                  <td>#{HTML.escape(address)}</td>
                  <td>#{HTML.escape(rs.read(String))}</td>
                  <td>#{size.humanize_bytes}</td>
                </tr>
              "
            end
          end
        end
        context.response.print "</table>"
      elsif context.request.path == "/add"
        name = context.request.form_params["name"]
        address = Random::Secure.hex 32
        DB.open "sqlite3://#{dbs.main}" do |db|
          db.exec "insert into addresses (id, name) values (?, ?)", address, name
        end
        DB.open "sqlite3://#{dbs.by_address address}" do |db|
          db.exec "create table writes (vsn integer primary key autoincrement, data blob)"
        end
        context.response.redirect "/"
      else
        context.response.respond_with_status 404, "Path not found: #{context.request.path}"
      end
    end
  end
end