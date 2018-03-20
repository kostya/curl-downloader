require "../src/curl-downloader"

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