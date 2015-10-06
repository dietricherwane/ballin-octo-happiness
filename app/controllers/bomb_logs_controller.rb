class BombLogsController < ApplicationController

  def last_request
    render text: (BombLog.last.sent_url rescue "Error While Displaying °-°")
  end

  def last_return
    render text: "Notification d'erreur: " + (Log.last.error_response rescue "Error While Displaying °�") +  " | Notification de succès :" + (Log.last.response_log rescue "Error While Displaying °-°")
  end

end
