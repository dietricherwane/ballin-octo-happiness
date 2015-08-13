class CertifiedAgentsController < ApplicationController

  def create
    certified_agent = CertifiedAgent.new(certified_agent_id: params[:certified_agent_id])
    status = "0"
    if certified_agent.save
      status = "1"
    end

    render text: status
  end

end
