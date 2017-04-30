require "curl-crystal"

module Curl
  def self.error_description(ret)
    String.new(LibCurl.curl_easy_strerror(ret))
  end
end

require "./curl-downloader/*"
