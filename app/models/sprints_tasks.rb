class SprintsTasks < Issue
  acts_as_list :column => "ir_position"

  ORDER = 'case when issues.ir_position is null then 1 else 0 end ASC, case when issues.ir_position is NULL then issues.id else issues.ir_position end ASC'

  def self.get_tasks_by_status(project, status, sprint, user)
    projects = []
    tasks = []
    Project.where(["id = ? or parent_id = ?", project.id, project.id]).select('id').all().each{|proj| projects << proj.id}
    cond = ["issues.project_id in (?) and status_id = ?", projects, status]
    unless sprint.nil?
      if sprint == 'null'
        cond[0] += ' and fixed_version_id is null'
      else
        cond[0] += ' and fixed_version_id = ?'
        cond << sprint
      end
    end
    unless user.nil?
      cond[0] += ' and assigned_to_id = ?'
      user = User.current.id if user == 'current'
      cond << user
    end
    SprintsTasks.select('issues.*, sum(hours) as spent').order(SprintsTasks::ORDER).where(cond).group("issues.id").joins([:status]).joins("left join time_entries ON time_entries.issue_id = issues.id").all().each{|task| tasks << task}
    
    
    
    return tasks
  end
  
  
  
  def self.get_my_tasks_by_status(status, sprint, user)
    projects = []
    tasks = []
    Project.where(["status=1"]).select('id').all().each{|proj| projects << proj.id}

    
    cond = ["issues.project_id in (?) AND status_id = ? AND assigned_to_id = ?", projects, status, User.current.id]
    SprintsTasks.select('issues.*, sum(hours) as spent').order(SprintsTasks::ORDER).where(cond).group("issues.id").joins([:status]).joins("left join time_entries ON time_entries.issue_id = issues.id").all().each{|task| tasks << task}
    return tasks
  end

  
  
  
  
  
  
  def self.get_all_tasks_by_status(status, sprint, user)
    tasks = []
    cond = ["status_id = ?", status]
    unless sprint.nil?
      if sprint == 'null'
        cond[0] += ' and fixed_version_id is null'
      else
        cond[0] += ' and fixed_version_id = ?'
        cond << sprint
      end
    end
    unless user.nil?
      cond[0] += ' and assigned_to_id = ?'
      user = User.current.id if user == 'current'
      cond << user
    end
    SprintsTasks.where(cond).select('issues.*, sum(hours) as spent').group('issues.id').joins([:status]).joins("left join time_entries ON time_entries.issue_id = issues.id").include([:assigned_to]).all()

                      
                                         
    return tasks
  end  
  
  

  def self.get_tasks_by_sprint(project, sprint)
    projects = []
    tasks = []
    Project.select("id").where(["id = ? or parent_id = ?", project.id, project.id]).all().each{|proj| projects << proj.id}
    cond = ["project_id in (?) and is_closed = ?", projects, false]
    unless sprint.nil?
      if sprint == 'null'
        cond[0] += ' and fixed_version_id is null'
      else
        cond[0] += ' and fixed_version_id = ?'
        cond << sprint
      end
    end
    SprintsTasks.order(SprintsTasks::ORDER).where(cond).joins(:status).all().each{|task| tasks << task}
    return tasks
  end

  def self.get_backlog(project)
    return SprintsTasks.get_tasks_by_sprint(project, 'null')
  end

  def move_after(prev_id)
    remove_from_list

    if prev_id.to_s == ''
      prev = nil
    else
      prev = SprintsTasks.find(prev_id)
    end

    if prev.blank?
      insert_at
      move_to_top
    elsif !prev.in_list?
      insert_at
      move_to_bottom
    else
      insert_at(prev.ir_position + 1)
    end
  end

  def update_and_position!(params)
    attribs = params.select{|k,v| k != 'id' && k != 'project_id' && SprintsTasks.column_names.include?(k) }
    attribs = Hash[*attribs.flatten]
    if params[:prev]
      move_after(params[:prev])
    end
    self.init_journal(User.current)
    update_attributes attribs
  end
end