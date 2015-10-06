class BombLogsController < ApplicationController

  def last_request
    render text: (BombLog.last.sent_url rescue "Error While Displaying °-°")
  end

  def last_return
<<<<<<< HEAD
    render text: "Notification d'erreur: " + (Log.last.error_response rescue "Error While Displaying °�") +  " | Notification de succès :" + (Log.last.response_log rescue "Error While Displaying °-°")
=======
    render text: "Error notification: " + (Log.last.error_log rescue "Error While Displaying °-°") + "Success notification: " + (Log.last.response_log rescue "Error While Displaying °-°")
>>>>>>> 9a0c64e84dc8851ef21ac60b2aa68e4b1fe8cbd3
  end

end
