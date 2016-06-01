class BombLogsController < ApplicationController

  def last_request
    @bomb_logs = BombLog.all.order("id DESC").limit(50)
    @bomb_body = ""

    unless @bomb_logs.blank?
      @bomb_logs.each do |bomb_log|
        @bomb_body << "--Remote ip: #{bomb_log.remote_ip}\n--URL: #{bomb_log.sent_url}\n\n\n\n"
      end
    end

    render text: @bomb_body
  end

  def last_return
    render text: "Error notification: " + (Log.last.error_log.to_s rescue "Error While Displaying °-°") + "Success notification: " + (Log.last.response_log.to_s rescue "Error While Displaying °-°")
  end

end
