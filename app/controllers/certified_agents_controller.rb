class CertifiedAgentsController < ApplicationController

  def create
    certified_agent = CertifiedAgent.new(certified_agent_id: params[:certified_agent_id], sub_certified_agent_id: params[:sub_certified_agent_id], account_number: params[:account_number], token: params[:token], wari_sub_agent_id: params[:wari_sub_agent_id])
    status = '0'

    if certified_agent.save
      status = '1'
    end

    render text: status
  end

end
