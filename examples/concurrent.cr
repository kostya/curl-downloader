require "../src/curl-downloader"

def request(url)
  d = Curl::Downloader.new
  d.url = url
  d
end

# run with examples/test-server.cr
reqs = Array.new((ARGV[0]? || 10).to_i) { request("http://127.0.0.1:8089/delay?n=#{rand(1.0)}") }

t = Time.now

reqs.each &.execute_async
reqs.each &.wait

reqs.each do |req|
  p req.url_effective
end

p Time.now - t
