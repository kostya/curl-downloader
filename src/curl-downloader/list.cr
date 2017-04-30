class Curl::List
  getter slist : Pointer(LibCurl::CurlSlist)

  def initialize
    @slist = Pointer(LibCurl::CurlSlist).new(0)
  end

  def add(str)
    @slist = LibCurl.curl_slist_append(@slist, str)
  end

  def free
    LibCurl.curl_slist_free_all(@slist)
  end
end
