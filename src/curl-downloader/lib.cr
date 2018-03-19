lib LibCurl
  type CURLM = Void*

  CURL_SOCKET_BAD = -1

  CURL_POLL_NONE      = 0
  CURL_POLL_IN        = 1
  CURL_POLL_OUT       = 2
  CURL_POLL_INOUT     = 3
  CURL_POLL_REMOVE    = 4
  CURL_SOCKET_TIMEOUT = CURL_SOCKET_BAD

  CURL_CSELECT_IN  = 0x01
  CURL_CSELECT_OUT = 0x02
  CURL_CSELECT_ERR = 0x04

  enum CURLMcode
    CURLM_CALL_MULTI_PERFORM = -1 # /* please call curl_multi_perform() or
    #     curl_multi_socket*() soon */
    CURLM_OK
    CURLM_BAD_HANDLE      # /* the passed-in handle is not a valid CURLM handle */
    CURLM_BAD_EASY_HANDLE # /* an easy handle was not good/valid */
    CURLM_OUT_OF_MEMORY   # /* if you ever get this, you're in deep sh*t */
    CURLM_INTERNAL_ERROR  # /* this is a libcurl bug */
    CURLM_BAD_SOCKET      # /* the passed in socket argument did not match */
    CURLM_UNKNOWN_OPTION  # /* curl_multi_setopt() with unsupported option */
    CURLM_ADDED_ALREADY   # /* an easy handle already added to a multi handle was
    #    attempted to get added - again */
    CURLM_RECURSIVE_API_CALL # /* an api function was called from inside a
    #   callback */
    CURLM_LAST
  end

  enum CURLMoption
    # # /* This is the socket callback function pointer */
    CURLMOPT_SOCKETFUNCTION = CURLOPTTYPE_FUNCTIONPOINT + 1

    # # /* This is the argument passed to the socket callback */
    CURLMOPT_SOCKETDATA = CURLOPTTYPE_OBJECTPOINT + 2

    # # /* set to 1 to enable pipelining for this multi handle */
    CURLMOPT_PIPELINING = CURLOPTTYPE_LONG + 3

    #  /* This is the timer callback function pointer */
    CURLMOPT_TIMERFUNCTION = CURLOPTTYPE_FUNCTIONPOINT + 4

    # /* This is the argument passed to the timer callback */
    CURLMOPT_TIMERDATA = CURLOPTTYPE_OBJECTPOINT + 5

    # /* maximum number of entries in the connection cache */
    CURLMOPT_MAXCONNECTS = CURLOPTTYPE_LONG + 6

    # /* maximum number of (pipelining) connections to one host */
    CURLMOPT_MAX_HOST_CONNECTIONS = CURLOPTTYPE_LONG + 7

    # /* maximum number of requests in a pipeline */
    CURLMOPT_MAX_PIPELINE_LENGTH = CURLOPTTYPE_LONG + 8

    # /* a connection with a content-length longer than this
    #    will not be considered for pipelining */
    CURLMOPT_CONTENT_LENGTH_PENALTY_SIZE = CURLOPTTYPE_OFF_T + 9

    # /* a connection with a chunk length longer than this
    #    will not be considered for pipelining */
    CURLMOPT_CHUNK_LENGTH_PENALTY_SIZE = CURLOPTTYPE_OFF_T + 10

    # /* a list of site names(+port) that are blacklisted from
    #    pipelining */
    CURLMOPT_PIPELINING_SITE_BL = CURLOPTTYPE_OBJECTPOINT + 11

    # /* a list of server types that are blacklisted from
    #    pipelining */
    CURLMOPT_PIPELINING_SERVER_BL = CURLOPTTYPE_OBJECTPOINT + 12

    # /* maximum number of open connections in total */
    CURLMOPT_MAX_TOTAL_CONNECTIONS = CURLOPTTYPE_LONG + 13

    #  /* This is the server push callback function pointer */
    CURLMOPT_PUSHFUNCTION = CURLOPTTYPE_FUNCTIONPOINT + 14

    # /* This is the argument passed to the server push callback */
    CURLMOPT_PUSHDATA = CURLOPTTYPE_OBJECTPOINT + 15

    CURLMOPT_LASTENTRY # /* the last unused */

  end

  enum CURLMSG
    CURLMSG_NONE # /* first, not used */
    CURLMSG_DONE # /* This easy handle has completed. 'result' contains
    #   the CURLcode of the transfer */
    CURLMSG_LAST # /* last, not used */
  end

  struct CURLMsg
    msg : CURLMSG       # /* what this message means */
    easy_handle : CURL* # /* the handle it concerns */
    code : CURLcode        # /* message-specific data */
  end

  alias CURL_SOCKET_T = Int32
  type CURL_SOCKET_CALLBACK = (CURL*,  # /* easy handle */
CURL_SOCKET_T,                         # /* socket */
Int32,                                 # /* see above */
Void*,                                 # /* private callback pointer */
Void*) -> Int32                        # /* private socket pointer */

  # /*
  #  * Name:    curl_multi_timer_callback
  #  *
  #  * Desc:    Called by libcurl whenever the library detects a change in the
  #  *          maximum number of milliseconds the app is allowed to wait before
  #  *          curl_multi_socket() or curl_multi_perform() must be called
  #  *          (to allow libcurl's timed events to take place).
  #  *
  #  * Returns: The callback should return zero.
  #  */

  type CURL_MULTI_TIMER_CALLBACK = (CURLM*,  # /* multi handle */
LibC::Long,                                  # /* see above */
Void*) -> Int32                              # /* private callback pointer */

  fun curl_multi_init : CURLM*
  fun curl_multi_cleanup(multi_handle : CURLM*) : CURLMcode

  fun curl_multi_add_handle(multi_handle : CURLM*, easy_handle : CURL*) : CURLMcode
  fun curl_multi_remove_handle(multi_handle : CURLM*, easy_handle : CURL*) : CURLMcode

  fun curl_multi_setopt(multi_handle : CURLM*, option : CURLMoption, ...) : CURLMcode

  # /*
  #  * Name:    curl_multi_assign()
  #  *
  #  * Desc:    This function sets an association in the multi handle between the
  #  *          given socket and a private pointer of the application. This is
  #  *          (only) useful for curl_multi_socket uses.
  #  *
  #  * Returns: CURLM error code.
  #  */

  fun curl_multi_assign(multi_handle : CURLM*, sockfd : CURL_SOCKET_T, sockp : Void*) : CURLMcode

  #  /*
  #   * Name:    curl_multi_perform()
  #   *
  #   * Desc:    When the app thinks there's data available for curl it calls this
  #   *          function to read/write whatever there is right now. This returns
  #   *          as soon as the reads and writes are done. This function does not
  #   *          require that there actually is data available for reading or that
  #   *          data can be written, it can be called just in case. It returns
  #   *          the number of handles that still transfer data in the second
  #   *          argument's integer-pointer.
  #   *
  #   * Returns: CURLMcode type, general multi error code. *NOTE* that this only
  #   *          returns errors etc regarding the whole multi stack. There might
  #   *          still have occurred problems on individual transfers even when
  #   *          this returns OK.
  #   */
  fun curl_multi_perform(multi_handle : CURLM*, running_handles : Int32*) : CURLMcode

  fun curl_multi_socket_action(multi_handle : CURLM*, s : CURL_SOCKET_T, ev_bitmask : Int32, running_handles : Int32*) : CURLMcode

  # /*
  #  * Name:    curl_multi_info_read()
  #  *
  #  * Desc:    Ask the multi handle if there's any messages/informationals from
  #  *          the individual transfers. Messages include informationals such as
  #  *          error code from the transfer or just the fact that a transfer is
  #  *          completed. More details on these should be written down as well.
  #  *
  #  *          Repeated calls to this function will return a new struct each
  #  *          time, until a special "end of msgs" struct is returned as a signal
  #  *          that there is no more to get at this point.
  #  *
  #  *          The data the returned pointer points to will not survive calling
  #  *          curl_multi_cleanup().
  #  *
  #  *          The 'CURLMsg' struct is meant to be very simple and only contain
  #  *          very basic information. If more involved information is wanted,
  #  *          we will provide the particular "transfer handle" in that struct
  #  *          and that should/could/would be used in subsequent
  #  *          curl_easy_getinfo() calls (or similar). The point being that we
  #  *          must never expose complex structs to applications, as then we'll
  #  *          undoubtably get backwards compatibility problems in the future.
  #  *
  #  * Returns: A pointer to a filled-in struct, or NULL if it failed or ran out
  #  *          of structs. It also writes the number of messages left in the
  #  *          queue (after this read) in the integer the second argument points
  #  *          to.
  #  */
  fun curl_multi_info_read(multi_handle : CURLM*, msgs_in_queue : Int32*) : CURLMsg*
end
