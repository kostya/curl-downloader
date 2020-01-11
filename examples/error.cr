require "../src/curl-downloader"

d = Curl::Downloader.new
d.url = ""

d.execute

p d.code
p d.error_description

d = Curl::Downloader.new
d.url = "1.1.1.1"
d.timeout = 1.seconds

d.execute

p d.code
p d.error_description
