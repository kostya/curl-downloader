require "../src/curl-downloader"

def request(url)
  d = Curl::Downloader.new
  d.url = url
  d
end

MY_MULTI = LibCurl.curl_multi_init
Curl::Downloader.start_polling(interval: 0.1.seconds, multi: MY_MULTI)

# run with examples/test-server.cr
reqs = Array.new((ARGV[0]? || 100).to_i) { request("http://127.0.0.1:8089/delay?n=#{rand(10.0)}") }

p :start

t = Time.now

reqs.each { |r| r.execute_async(MY_MULTI) }
reqs.each &.wait

reqs.each do |req|
  p req.url_effective
end

p Time.now - t
