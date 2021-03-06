class TimesheetsController < ApplicationController
  before_action :load_user

  before_action :login_required
  before_action :set_owner_check_object, :only => [:index]
  before_action :set_timesheet,          :only => [:edit, :update]
  before_action :owner_required,         :only => [:edit, :update, :index]

  def edit
  end

  def index
    @timesheets = timesheets.all
  end

  def update
    if @timesheet.update_attributes(timesheet_params_with_status)
      redirect_user
    else
      flash[:alert] = "Action failed"
      render :action => "edit"
    end
  end

  private

  def redirect_user
    if user_submitted?
      mixpanel_event("Timesheet Submission", @user, @timesheet)
      redirect_to @user, notice: "Your timesheet has been submitted"
    elsif user_reopened?
      mixpanel_event("Timesheet Reopening", @user, @timesheet)
      redirect_to edit_user_timesheet_path(@user, @timesheet), notice: "Timesheet reopened"
    elsif @timesheet.calendar_events
      mixpanel_event("Calendar events extraction", @user, @timesheet)
      redirect_to edit_user_timesheet_path(@user, @timesheet), notice: "Calendar events extracted"
    else
      mixpanel_event("Timesheet Saving", @user, @timesheet)
      redirect_to edit_user_timesheet_path(@user, @timesheet), notice: "Timesheet saved"
    end
  end

  def set_timesheet
    @owner_check_object = @timesheet = timesheets.find(params[:id])
  end

  def set_owner_check_object
    @owner_check_object = timesheets.first
  end

  def load_user
    @user = User.find(params[:user_id])
  end

  def timesheets
    @user ? @user.timesheets : Timesheet
  end

  def user_submitted?
    params[:commit] == "Submit Timesheet"
  end

  def user_reopened?
    params[:commit] == "Reopen Timesheet"
  end

  def timesheet_params_with_status
    if user_submitted?
      timesheet_params.merge(:status => "submitted")
    elsif user_reopened?
      timesheet_params.merge(:status => "reopened")
    else
      timesheet_params
    end
  end

  def timesheet_params
    params.require(:timesheet).permit(:comments, :status, :tenbis_usage, :calendar_events,
      :days_attributes => [:id, :day_type, :value, :comment])
  end

  def mixpanel_event(event_name, user, timesheet)
    track_event(event_name, distinct_id: user.id,
                "Start date" => timesheet.start_date, "End date" => timesheet.end_date, "$first_name" => user.first_name,
                "$last_name" => user.last_name, "$email" => user.email)
  end
end
