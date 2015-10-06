class BombLogsController < ApplicationController

  def last_request
    render text: (BombLog.last.sent_url rescue "Error While Displaying °-°")
  end

  def last_return
    render text: (Log.last.inspect rescue "Error While Displaying °-°")
  end

end
