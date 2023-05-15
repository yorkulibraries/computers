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
      @computers = Computer.attached_to_location.in_use.order('last_ping DESC');
    when "not_in_use"
      @computers = Computer.attached_to_location.not_in_use.order('last_ping DESC');
    when "pinging"
      @computers = Computer.attached_to_location.pinging.order('last_ping DESC');
    when "not_pinging"
      @computers = Computer.attached_to_location.not_pinging.order('last_ping DESC');
    when "staying_active"
      @computers = Computer.attached_to_location.staying_active.order('last_ping DESC');
    when "not_staying_active"
      @computers = Computer.attached_to_location.not_staying_active.order('last_ping DESC');
    when "never_ping"
      @computers = Computer.attached_to_location.never_ping.order('last_ping DESC');
    when "never_used"
      @computers = Computer.attached_to_location.never_used.order('last_ping DESC');
    else
      @computers = Computer.attached_to_location.in_use.order('last_ping DESC');
    end

  end

end
