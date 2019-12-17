class AdtaskinlController < ApplicationController
  before_action :find_project, :authorize, :except=> :update
  
  def update
    task = SprintsTasks.find(params[:id])
    begin
      result = task.update_and_position!(params)
    rescue => e
      render :text => e.message.blank? ? e.to_s : e.message, :status => 400
      return
    end

    task.reload
    status = (result ? 200 : 400)

    respond_to do |format|
      format.html { render :nothing => true, :status => status }
    end
  end

  def create
  	trackers_avail=@project.trackers().select('id').all().pluck(:id)
    attribs = params.select{|k,v| k != 'id' and SprintsTasks.column_names.include? k }
    attribs = (attribs || {}).deep_dup
    
    #attribs = Hash[*attribs.flatten]
    #attribs['tracker_id'] = attribs['tracker_id'] || Setting.plugin_AgileDwarf[:tracker]
    
	  #if !trackers_avail.include?(attribs['tracker_id'])
    #	attribs['tracker_id']=@project.trackers().first()
    #end

    #attribs['author_id'] = User.current.id
    #task = SprintsTasks.new(attribs)
    task = SprintsTasks.new

    tracker_id = attribs.delete(:tracker_id)
    tracker_id = Setting.plugin_AgileDwarf[:tracker] unless tracker_id.present?
    unless trackers_avail.include?(tracker_id)
    	tracker_id = @project.trackers.first
    end

    task.tracker_id = tracker_id
    task.author_id = User.current.id
    task.safe_attributes = attribs
    begin
      task.save!
    rescue => e
      render :text => e.message.blank? ? e.to_s : e.message, :status => 400
      return
    end

    status = (task.errors.empty? ? 200 : 400)

    respond_to do |format|
      format.html { render :text => task.id, :status => status}
    end
  end

  def tooltip
    task = SprintsTasks.find(params[:id])
    text = task.description.blank? ? l(:label_task_field_description_empty) : task.description
    text.gsub!(/\n/, '<br/>')
    respond_to do |format|
      format.html { render :text => text, :status => 200 }
    end
  end

  def spent
    spenttime = TimeEntry.new({:hours => params[:hours], :activity_id => Setting.plugin_AgileDwarf[:activity], :user => User.current, :project => @project, :spent_on => Date.today,
                               :issue_id => params[:id]})
    begin
      spenttime.save!
    rescue => e
      render :text => e.message.blank? ? e.to_s : e.message, :status => 400
      return
    end

    status = (spenttime.errors.empty? ? 200 : 400)

    respond_to do |format|
      format.html { render :text => spenttime.hours, :status => status }
    end
  end


  def inplace
    # element_id filtered too!
    attribs = params.select{|k,v| k != 'id' && k != 'project_id' && SprintsTasks.column_names.include?(k) }
    attribs = attribs.flatten
    param_id = attribs[0]
    attribs = Hash[*attribs]
    if attribs["estimated_hours"] != nil
      val = attribs["estimated_hours"].to_f
      if val == 0.0 && val.to_s == "0.0"
        render :text => "Please insert integer!"
        return
      end
    end
    #render :text => "Please insert integer!"
    #task = SprintsTasks.find(params[:id], :include => :assigned_to)
    task = SprintsTasks.includes(:assigned_to).find(params[:id])
    begin
      task.init_journal(User.current)
      result = task.update_attributes(attribs)
    rescue => e
      render :text => e.message.blank? ? e.to_s : e.message, :status => 400
      return
    end

    status = (result ? 200 : 400)
    task.reload

    new_value = param_id == 'assigned_to_id' ? task.assigned_to : task[param_id]
    respond_to do |format|
      format.html { render :text => new_value, :status => status }
    end
  end

  private

  def find_project
    # @project variable must be set before calling the authorize filter
    if params[:id]
    	@project=Project.find(Issue.find(params[:id]).project_id)
    else
	    @project = Project.find(params[:project_id])
	end
  end
end
