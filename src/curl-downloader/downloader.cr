require "gzip"

class Curl::Downloader
  VERSION = "0.3"

  getter code

  @started_at : Time?
  @finished_at : Time?

  def initialize
    @content_buffer = Buffer.new
    @headers_buffer = Buffer.new
    @curl = LibCurl.curl_easy_init
    @started_at = nil
    @finished_at = nil
    @code = LibCurl::CURLcode::CURLE_OK
    @finalized = false
    @temp_int = 0_i32
    @temp_f64 = 0.0_f64
    @temp_pointer = Pointer(UInt8).new(0)
    @lists = [] of List

    set_opt(LibCurl::CURLoption::CURLOPT_WRITEFUNCTION, WRITE_DATA_CALLBACK)
    set_opt(LibCurl::CURLoption::CURLOPT_WRITEDATA, @content_buffer.as(Void*))
    set_opt(LibCurl::CURLoption::CURLOPT_HEADERDATA, @headers_buffer.as(Void*))
    set_opt(LibCurl::CURLoption::CURLOPT_NOPROGRESS, 1)
    set_opt(LibCurl::CURLoption::CURLOPT_NOSIGNAL, 1)
  end

  def set_opt(opt, val)
    LibCurl.curl_easy_setopt @curl, opt, val
  end

  # ex: body = "bla=1&gg=2"
  def body=(body : String)
    set_opt(LibCurl::CURLoption::CURLOPT_POSTFIELDS, body)
  end

  # ex: method = "POST", default: "GET"
  def method=(method : String)
    set_opt(LibCurl::CURLoption::CURLOPT_CUSTOMREQUEST, method)
  end

  # ex: url = "https://google.com/"
  def url=(url : String)
    set_opt(LibCurl::CURLoption::CURLOPT_URL, url)
  end

  # ex: auth_basic = "login:password"
  def auth_basic=(auth : String)
    set_opt(LibCurl::CURLoption::CURLOPT_USERPWD, auth)
  end

  # ex: auth_digest = "login:password"
  def auth_digest=(auth : String)
    set_opt(LibCurl::CURLoption::CURLOPT_USERPWD, auth)
    set_opt(LibCurl::CURLoption::CURLOPT_HTTPAUTH, 2)
  end

  # ex: accept_encoding = "gzip, deflate"
  def accept_encoding=(enc : String)
    set_opt(LibCurl::CURLoption::CURLOPT_ACCEPT_ENCODING, enc)
  end

  # ex: timeout = 60 # seconds
  def timeout=(t : Int32 | Time::Span)
    set_opt(LibCurl::CURLoption::CURLOPT_TIMEOUT, t.to_i)
  end

  # ex: connect_timeout = 10 # seconds
  def connect_timeout=(t : Int32 | Time::Span)
    set_opt(LibCurl::CURLoption::CURLOPT_CONNECTTIMEOUT, t.to_i)
  end

  # ex: ssl_verifypeer = false
  def ssl_verifypeer=(flag : Bool)
    set_opt(LibCurl::CURLoption::CURLOPT_SSL_VERIFYPEER, flag ? 1 : 0)
  end

  # ex: ssl_verifyhost = false
  def ssl_verifyhost=(flag : Bool)
    set_opt(LibCurl::CURLoption::CURLOPT_SSL_VERIFYHOST, flag ? 1 : 0)
  end

  def verbose!
    set_opt(LibCurl::CURLoption::CURLOPT_VERBOSE, 1)
  end

  # ex: interface = "127.0.0.1"
  def interface=(bind : String)
    set_opt(LibCurl::CURLoption::CURLOPT_INTERFACE, bind)
  end

  # ex: proxy = "http://127.0.0.1:443", proxy = "socks5://127.0.0.1:443"
  def proxy=(proxy : String)
    set_opt(LibCurl::CURLoption::CURLOPT_PROXY, proxy)
  end

  # ex: cookie_jar = "/tmp/bla.txt"
  def cookie_jar=(path : String)
    set_opt(LibCurl::CURLoption::CURLOPT_COOKIEJAR, path)
  end

  # ex: cookie_file = "/tmp/bla.txt"
  def cookie_file=(path : String)
    set_opt(LibCurl::CURLoption::CURLOPT_COOKIEFILE, path)
  end

  # set headers, ex: headers = ["Accept: text/html", "User-Agent: Bla"]
  def headers=(headers : Array(String))
    list = List.new
    @lists << list
    headers.each { |h| list.add(h) }
    set_opt(LibCurl::CURLoption::CURLOPT_HTTPHEADER, list.slist)
  end

  # set headers, ex: headers = {"Accept" => "text/html", "User-Agent" => "Bla"}
  def headers=(headers : Hash(String, String))
    list = List.new
    @lists << list
    headers.each { |k, v| list.add("#{k}: #{v}") }
    set_opt(LibCurl::CURLoption::CURLOPT_HTTPHEADER, list.slist)
  end

  # ex: resolve = ["bla.ru:80:127.0.0.1"]
  def resolve=(resolve : Array(String))
    list = List.new
    @lists << list
    resolve.each { |h| list.add(h) }
    set_opt(LibCurl::CURLoption::CURLOPT_RESOLVE, list.slist)
  end

  # set to follow redirects
  def follow_redirects!
    set_opt(LibCurl::CURLoption::CURLOPT_FOLLOWLOCATION, 1)
  end

  # ex: max_redirects = 10
  def max_redirects=(max_redirs : Int32)
    set_opt(LibCurl::CURLoption::CURLOPT_MAXREDIRS, max_redirs)
  end

  # to execute HEAD method
  #   downloader.method = "HEAD"
  #   downloader.no_body!
  def no_body!
    set_opt(LibCurl::CURLoption::CURLOPT_NOBODY, 1)
  end

  # =============================== execution =================================

  WRITE_DATA_CALLBACK = ->(ptr : UInt8*, size : LibC::SizeT, nmemb : LibC::SizeT, data : Void*) do
    slice = Bytes.new(ptr, size * nmemb)
    data.as(Buffer).receive_data(slice)
    size * nmemb
  end

  # run execution
  def execute
    return if @finalized
    @started_at = Time.now
    @code = LibCurl.curl_easy_perform @curl
    @finished_at = Time.now
    true
  end

  # call this after execution done, also this called when object finalized
  def free
    return if @finalized
    @finalized = true
    LibCurl.curl_easy_cleanup @curl
    @lists.each &.free
  end

  def finalize
    free
  end

  def clear_buffers
    @content_buffer.io.clear
    @headers_buffer.io.clear
  end

  # ================== getters =======================

  def ok?
    @code == LibCurl::CURLcode::CURLE_OK
  end

  def error_description
    Curl.error_description(@code)
  end

  def content
    if gzip?
      Gzip::Reader.open(@content_buffer.io.rewind) do |gzip|
        gzip.gets_to_end
      end
    else
      @content_buffer.io.to_s
    end
  rescue Gzip::Error
    @content_buffer.io.rewind.to_s
  end

  def headers
    @headers_buffer.io.to_s
  end

  def gzip?
    headers.split("\n").any? do |row|
      row.includes?("content-encoding") && row.includes?("gzip")
    end
  end

  def http_status
    get_info_int(LibCurl::CURLINFO::CURLINFO_RESPONSE_CODE)
  end

  def url_effective
    get_info_string(LibCurl::CURLINFO::CURLINFO_EFFECTIVE_URL)
  end

  def content_type
    get_info_string(LibCurl::CURLINFO::CURLINFO_CONTENT_TYPE)
  end

  def redirects_count
    get_info_int(LibCurl::CURLINFO::CURLINFO_REDIRECT_COUNT)
  end

  def namelookup_time
    get_info_double(LibCurl::CURLINFO::CURLINFO_NAMELOOKUP_TIME)
  end

  def connect_time
    get_info_double(LibCurl::CURLINFO::CURLINFO_NAMELOOKUP_TIME)
  end

  def total_time
    get_info_double(LibCurl::CURLINFO::CURLINFO_TOTAL_TIME)
  end

  def redirect_time
    get_info_double(LibCurl::CURLINFO::CURLINFO_REDIRECT_TIME)
  end

  def num_connects
    get_info_int(LibCurl::CURLINFO::CURLINFO_NUM_CONNECTS)
  end

  def local_addr
    "#{get_info_string(LibCurl::CURLINFO::CURLINFO_LOCAL_IP)}:#{get_info_int(LibCurl::CURLINFO::CURLINFO_LOCAL_PORT)}"
  end

  def remote_addr
    "#{get_info_string(LibCurl::CURLINFO::CURLINFO_PRIMARY_IP)}:#{get_info_int(LibCurl::CURLINFO::CURLINFO_PRIMARY_PORT)}"
  end

  def duration
    if (finished_at = @finished_at) && (started_at = @started_at)
      finished_at - started_at
    end
  end

  def get_info_int(key)
    @temp_int = 0_i32
    LibCurl.curl_easy_getinfo(@curl, key, pointerof(@temp_int))
    @temp_int
  end

  def get_info_double(key)
    @temp_f64 = 0.0_f64
    LibCurl.curl_easy_getinfo(@curl, key, pointerof(@temp_f64))
    @temp_f64
  end

  def get_info_string(key)
    @temp_pointer = Pointer(UInt8).new(0)
    LibCurl.curl_easy_getinfo(@curl, key, pointerof(@temp_pointer))
    unless @temp_pointer.null?
      String.new @temp_pointer
    end
  end
end
