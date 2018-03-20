# curl-downloader

Downloader based on libcurl [binding](https://github.com/blocknotes/curl-crystal). This lib is not natural for crystal because libcurl is thread blocking, so for concurrent execution need to use something like [run_with_fork](https://github.com/kostya/run_with_fork)

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

## Example with run_with_fork, to execute request in the background, and not to lock crystal main thread

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