class StatusController < ApplicationController

  def index
    @locations = Location.all

    respond_to do |format|
      format.html
      format.json { render json: @locations }
    end

  end

  def by_status
    @status_name = params[:status].humanize

    case params[:status]
    when "in_use"
      @computers = Computer.attached_to_location.in_use
    when "not_in_use"
      @computers = Computer.attached_to_location.not_in_use
    when "pinging"
      @computers = Computer.attached_to_location.pinging
    when "not_pinging"
      @computers = Computer.attached_to_location.not_pinging
    when "staying_active"
      @computers = Computer.attached_to_location.staying_active
    when "not_staying_active"
      @computers = Computer.attached_to_location.not_staying_active
    when "never_ping"
      @computers = Computer.attached_to_location.never_ping
    when "never_used"
      @computers = Computer.attached_to_location.never_used
    else
      @computers = Computer.attached_to_location.in_use
    end

  end

end
