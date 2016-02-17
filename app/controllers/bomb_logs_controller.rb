class BombLogsController < ApplicationController

  def last_request
    render text: (BombLog.last.sent_url rescue "Error While Displaying °-°")
  end

  def last_return
    render text: "Error notification: " + (Log.last.error_log.to_s rescue "Error While Displaying °-°") + "Success notification: " + (Log.last.response_log.to_s rescue "Error While Displaying °-°")
  end

end
