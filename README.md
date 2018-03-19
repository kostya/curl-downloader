# curl-downloader

Powerfull http-client for Crystal based on libcurl [binding](https://github.com/blocknotes/curl-crystal). LibCurl is much more powerfull than std crystal http-client, with features like: redirects, dns caching, interface binding, socks, proxing, sessions, and many others. This lib is not io or thread blocking, because uses for execution combination of curl multi interface, libevent, and crystal channels. Ready to use for high concurrency requests.

## Installation

    $ brew install curl
    $ apt-get install libcurl-dev

Add this to your application's `shard.yml`:

```yaml
dependencies:
  curl-downloader:
    github: kostya/curl-downloader
```

## Usage

```crystal
require "curl-downloader"

d = Curl::Downloader.new
d.url = "https://google.com/"
d.follow_redirects!
d.headers = {"User-Agent" => "Opera 9.51"}
d.timeout = 60
d.cookie_jar = "/tmp/downloader_test.txt"
d.cookie_file = "/tmp/downloader_test.txt"

# execute request, fiber blocking
d.execute

# fetch results
p d.code
p d.http_status

p d.content[0..100] + "..."
p d.headers.split("\r\n")

p d.url_effective
p d.content_type

d.free
```

## Concurrent execution

```crystal
require "curl-downloader"

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
```