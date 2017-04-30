require "../src/curl-downloader"
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
