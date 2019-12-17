class AdmytasksController < ApplicationController
  #before_action :authorize

  def list
    # data for filters
    @sprints = Sprints.my_sprints()
    @assignables = User.all()
    @assignables_list = {}

    # filter values
    @selected = params[:sprint] || (@sprints[0].nil? ? 'all' : @sprints[0].id.to_s)
    case @selected
      when 'all'
        sprint = nil
      when 'none'
        sprint = 'null'
      else
        sprint = @selected
    end
    user = @user = params[:user] || 'current'
    user = nil if @user == 'all'

    @plugin_path = File.join(Redmine::Utils.relative_url_root, 'plugin_assets', 'AgileDwarf')

    status_ids = []
    colcount = Setting.plugin_AgileDwarf[:stcolumncount].to_i
    for i in 1 .. colcount
      status_ids << Setting.plugin_AgileDwarf[('stcolumn' + i.to_s).to_sym].to_i
    end
    @statuses = {}
    IssueStatus.find(status_ids).each {|x| @statuses[x.id] = x.name}
    @columns = []
    for i in 0 .. colcount - 1
      @columns << {:tasks => SprintsTasks.get_my_tasks_by_status(status_ids[i], sprint, user), :id => status_ids[i]}
    end
  end

  private

  def find_project
    # @project variable must be set before calling the authorize filter
    #@project = Project.find(params[:project_id])
  end
end
