
class GMFileFormatError < RuntimeError
end

class GMErrorHandler
  def GMErrorHandler.handle(status, message)
    puts message
    exit status
  end

  def GMErrorHandler.notice(status, message)
    puts message
  end
end

