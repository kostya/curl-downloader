require "./spec_helper"

describe Curl::Downloader do
  it "simple test" do
    d = Curl::Downloader.new
    d.url = "https://google.com/"
    d.follow_redirects!
    d.headers = {"User-Agent" => "Opera 9.51"}
    d.timeout = 60
    d.cookie_jar = "/tmp/downloader_test.txt"
    d.cookie_file = "/tmp/downloader_test.txt"

    d.execute

    d.ok?.should eq true
    d.http_status.should eq 200

    d.content.bytesize.should be > 10_000
    d.headers.split("\r\n").size.should be > 10

    d.url_effective.to_s.should contain("google")
    d.content_type.should eq "text/html; charset=UTF-8"
    d.free
  end
end
