require_dependency 'enabled_module'

module EnabledModulePatch
  def self.prepended(base)
    base.send(:prepend, InstanceMethods)
    base.class_eval do

    end
  end

  module InstanceMethods
    # init task positions when enable module
    def module_enabled
      if name == 'scrum'
        max = 0
        ActiveRecord::Base.connection.execute("select max(ir_position) from issues where project_id =  #{self.project_id}").each{|row| max = row[0]}
        ActiveRecord::Base.connection.execute "update issues set ir_position = #{max} + id where ir_position is null"
        logger.info("Module attached to project #{self.project_id}")
      end
      super
    end
  end
end