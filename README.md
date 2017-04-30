# curl-downloader

Downloader based on libcurl [binding](https://github.com/blocknotes/curl-crystal). This lib is not natural for crystal because libcurl is thread blocking, so for concurrent execution need to use something like [thread_pool](https://github.com/kostya/thread_pool)

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

## Example with thread_pool, to execute request in the background, and not to lock crystal main thread

```crystal
require "curl-downloader"
require "thread_pool"

class Task
  include ThreadPool::Task
  def initialize(@downloader : Curl::Downloader); end
  def execute; @downloader.execute; end
end

pool = ThreadPool.new(size: 4).run

downloader = Curl::Downloader.new
downloader.url = "http://127.0.0.1:3000/"
downloader.timeout = 2

pool.execute(Task.new(downloader))

if downloader.ok?
  p :ok
  p downloader.http_status
else
  p downloader.error_description
end

downloader.free
```
