class Sprints < Version
  validate :start_and_end_dates

  class << self
    def open_sprints(project)
      projects = []
      Project.where(["id = ? or parent_id = ?", project.id, project.id]).select('id').all().each{|proj| projects << proj.id}
      where([ "status = 'open' and project_id in (?)", projects ]).order('ir_start_date ASC, ir_end_date ASC')
    end
    def all_sprints(project)
      projects = []
      #Project.find(:all, :select => 'id', :conditions => ["id = ? or parent_id = ?", project.id, project.id]).each{|proj| projects << proj.id}
      Project.select('id').where(["id = ? or parent_id = ?", project.id, project.id]).all().each{|proj| projects << proj.id}
      where([ "project_id in (?)", projects ]).order('ir_start_date ASC, ir_end_date ASC')
    end
    
     def my_sprints()
      projects = []
      Project.all().each{|proj| projects << proj.id}
      where([ "status = 'open' and project_id in (?)", projects ]).order('ir_start_date ASC, ir_end_date ASC')
    end
    def all_my_sprints(project)
      projects = []
      #Project.find(:all, :select => 'id', :conditions => ["id = ? or parent_id = ?", project.id, project.id]).each{|proj| projects << proj.id}
      Project.all().each{|proj| projects << proj.id}
      where([ "project_id in (?)", projects ]).order('ir_start_date ASC, ir_end_date ASC')
    end   
    
    
    
  end

  def start_and_end_dates
    errors.add_to_base("Sprint cannot end before it starts") if self.ir_start_date && self.ir_end_date && self.ir_start_date >= self.ir_end_date
  end

  def tasks
    SprintsTasks.get_tasks_by_sprint(self.project, self.id)
  end

end
