class Scheduler
  def self.raw_event_base
    @@eb.@base
  end
end

lib LibEvent2
  fun event_pending(ev : Event, events : LibEvent2::EventFlags, tv : LibC::Timeval*) : Int32
end
