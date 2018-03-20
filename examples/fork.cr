require "../src/curl-downloader"
require "run_with_fork"
require "msgpack"

struct Response
  MessagePack.mapping({
    code: Int32,
    http_status: Int32,
    content: String,
  })
end

pid, r = Process.run_with_fork do |w|
  d = Curl::Downloader.new
  d.url = "https://google.com/"
  d.follow_redirects!
  d.headers = {"User-Agent" => "Opera 9.51"}
  d.timeout = 60
  d.cookie_jar = "/tmp/downloader_test.txt"
  d.cookie_file = "/tmp/downloader_test.txt"

  d.execute

  {code: d.code, 
    http_status: d.http_status,
    content: d.content}.to_msgpack(w)
end

resp = Response.from_msgpack(r)
p resp
