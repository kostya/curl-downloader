# curl-downloader

Powerfull http-client for Crystal based on [libcurl](https://curl.haxx.se/libcurl/) [binding](https://github.com/blocknotes/curl-crystal). LibCurl is much more powerfull than std crystal http-client, with features like: redirects, interface binding, socks, proxing, sessions, and many others. LibCurl is usually hard to use directly in event based languages like Crystal, because it block main thread. To avoid thread blocking you can use [run_with_fork](https://github.com/kostya/run_with_fork).

## Installation

    $ brew install curl
    $ apt-get install libcurl-dev

## Installation

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

d.execute

p d.code
p d.http_status

p d.content[0..100] + "..."
p d.headers.split("\r\n")

p d.url_effective
p d.content_type

d.free
```

## Example run_with_fork

```crystal
require "curl-downloader"
require "run_with_fork"
require "msgpack"

struct Response
  MessagePack.mapping({
    code: Int32,
    http_status: Int32,
    content: String,
  })
end

r = Process.run_with_fork do |w|
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
```

## Example concurrent execution

```crystal
require "curl-downloader"
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
    r = Process.run_with_fork do |w|
      req.execute
      w.puts(req.url_effective)
    end

    ch.send r.gets.not_nil!
    r.close
  end
end

reqs.size.times { puts ch.receive }

p Time.now - t
```