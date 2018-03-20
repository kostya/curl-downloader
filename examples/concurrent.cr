require "../src/curl-downloader"
require "run_with_fork"

def request(url)
  d = Curl::Downloader.new
  d.url = url
  d
end

# run with examples/test-server.cr
reqs = Array.new((ARGV[0]? || 10).to_i) { request("http://127.0.0.1:8089/delay?n=#{rand(1.0)}") }

t = Time.now

ch = Channel(String).new

reqs.each do |req| 
  spawn do
    pid, r = Process.run_with_fork do |w|
      req.execute
      w.puts(req.url_effective)
    end

    ch.send r.gets.not_nil!
    r.close
  end
end

reqs.size.times { puts ch.receive }

p Time.now - t
