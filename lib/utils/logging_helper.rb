module Utils::LoggingHelper
  def format_msg(msg, method: nil)
    if method
      "#{self.class.name}.#{method}: #{msg}"
    else
      "#{self.class.name}: #{msg}"
    end
  end

  def __logger__
    @logger || Rails.logger
  end

  def log_info(msg, method: nil)
    fmt_msg = format_msg(msg, method: method)
    __logger__.info(fmt_msg)
  end

  def log_debug(msg, method: nil)
    fmt_msg = format_msg(msg, method: method)
    __logger__.debug(fmt_msg)
  end

  def log_warn(msg, method: nil)
    fmt_msg = format_msg(msg, method: method)
    __logger__.warn(fmt_msg)
  end

  def log_error(msg, method: nil)
    fmt_msg = format_msg(msg, method: method)
    __logger__.error(fmt_msg)
  end

  def log_fatal(msg, method: nil)
    fmt_msg = format_msg(msg, method: method)
    __logger__.fatal(fmt_msg)
  end
end