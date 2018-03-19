class Curl::Downloader
  @event : LibEvent2::Event?

  def del_multi_sock
    if event = @event
      LibEvent2.event_del(event)
    end
  end

  GCURL_EVENT_CB = ->(fd : Int32, kind : LibEvent2::EventFlags, data : Void*) do
    action = (kind & LibEvent2::EventFlags::Read ? LibCurl::CURL_CSELECT_IN : 0) |
             (kind & LibEvent2::EventFlags::Write ? LibCurl::CURL_CSELECT_OUT : 0)

    still_running = 0
    rc = LibCurl.curl_multi_socket_action(GCURL_MULTI, fd, action, pointerof(still_running))
    Curl::Downloader.check_multi_info

    if still_running <= 0
      if LibEvent2.event_pending(GCURL_TIMER_EVENT, LibEvent2::EventFlags::Timeout, nil) == 0
        LibEvent2.event_del(GCURL_TIMER_EVENT)
      end
    end

    Curl::Downloader.current_requests_count = still_running
    0
  end

  def set_multi_sock(fd, kind)
    del_multi_sock
    event = LibEvent2.event_new(Scheduler.raw_event_base, fd, kind, GCURL_EVENT_CB, nil)
    @event = event
    LibEvent2.event_add(event, nil)
  end

  def execute
    execute_async
    wait
    true
  end

  def execute_async
    LibCurl.curl_multi_add_handle(GCURL_MULTI, @curl)
  end

  def mark_finished
    @ch.send(true)
  rescue Channel::ClosedError
  end

  def wait
    @ch.receive
  end

  def self.check_multi_info
    while true
      msg = LibCurl.curl_multi_info_read(GCURL_MULTI, out msgs_left)
      break if msg.null?

      if msg.value.msg == LibCurl::CURLMSG::CURLMSG_DONE
        LibCurl.curl_multi_remove_handle(GCURL_MULTI, msg.value.easy_handle)

        d = Curl::Downloader.from_easy(msg.value.easy_handle)
        d.mark_finished
      end
    end
  end

  # Called from libcurl
  GCURL_SOCK_CB = ->(e : LibCurl::CURL*, s : LibCurl::CURL_SOCKET_T, act : Int32, cbp : Void*, sockp : Void*) do
    d = Curl::Downloader.from_easy(e)

    if act == LibCurl::CURL_POLL_REMOVE
      d.del_multi_sock
    else
      kind = (act & LibCurl::CURL_POLL_IN ? LibEvent2::EventFlags::Read : LibEvent2::EventFlags::None) |
             (act & LibCurl::CURL_POLL_OUT ? LibEvent2::EventFlags::Write : LibEvent2::EventFlags::None) |
             LibEvent2::EventFlags::Persist

      d.set_multi_sock(s, kind)
    end

    0
  end

  # Called from libcurl
  GCURL_MULTI_TIMER_CB = ->(multi : LibCurl::CURLM*, timeout_ms : LibC::Long, data : Void*) do
    timeout = LibC::Timeval.new(tv_sec: timeout_ms / 1000, tv_usec: (timeout_ms % 1000) * 1000)

    # /* TODO
    #  *
    #  * if timeout_ms is 0, call curl_multi_socket_action() at once!
    #  *
    #  * if timeout_ms is -1, just delete the timer
    #  *
    #  * for all other values of timeout_ms, this should set or *update*
    #  * the timer to the new value
    #  */

    if timeout_ms == 0
      still_running = 0
      LibCurl.curl_multi_socket_action(GCURL_MULTI, LibCurl::CURL_SOCKET_TIMEOUT, 0, pointerof(still_running))
      Curl::Downloader.current_requests_count = still_running
    elsif timeout_ms == -1
      LibEvent2.event_del(GCURL_TIMER_EVENT)
    else
      LibEvent2.event_add(GCURL_TIMER_EVENT, pointerof(timeout))
    end

    0
  end

  # /* Called by libevent when our timeout expires */
  GCURL_TIMER_CB = ->(fd : LibEvent2::EvutilSocketT, kind : LibEvent2::EventFlags, userp : Void*) do
    still_running = 0
    LibCurl.curl_multi_socket_action(GCURL_MULTI, LibCurl::CURL_SOCKET_TIMEOUT, 0, pointerof(still_running))
    Curl::Downloader.current_requests_count = still_running
    Curl::Downloader.check_multi_info
    0
  end

  GCURL_MULTI = begin
    multi = LibCurl.curl_multi_init
    LibCurl.curl_multi_setopt(multi, LibCurl::CURLMoption::CURLMOPT_SOCKETFUNCTION, GCURL_SOCK_CB)
    multi
  end

  GCURL_TIMER_EVENT = begin
    ev = LibEvent2.event_new(Scheduler.raw_event_base, LibCurl::CURL_SOCKET_TIMEOUT, LibEvent2::EventFlags::None, GCURL_TIMER_CB, nil)
    LibCurl.curl_multi_setopt(GCURL_MULTI, LibCurl::CURLMoption::CURLMOPT_TIMERFUNCTION, GCURL_MULTI_TIMER_CB)
    ev
  end

  @@current_requests_count = 0

  def self.current_requests_count
    @@current_requests_count
  end

  def self.current_requests_count=(c)
    @@current_requests_count = c
  end
end

# at_exit do
#   LibEvent2.event_del(GCURL_TIMER_EVENT)
#   LibCurl.curl_multi_cleanup(GCURL_MULTI)
# end
