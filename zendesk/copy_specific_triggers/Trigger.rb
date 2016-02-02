class CustomTicketField
  attr_reader :id, :type, :title, :description, :active, :required, :collapsed_for_agents, :title_in_portal, :visible_in_portal, :editable_in_portal, :required_in_portal, :removable, :system_field_options, :custom_field_options

  def initialize id, type, title, description, active, required, collapsed_for_agents, regexp_for_validation, title_in_portal, visible_in_portal, editable_in_portal, required_in_portal, tag, removable, system_field_options, custom_field_options
    @id = id
    @type = type
    @title = title
    @description = description
    @active = active
    @required = required
    @collapsed_for_agents = collapsed_for_agents
    @regexp_for_validation = regexp_for_validation
    @title_in_portal = title_in_portal
    @visible_in_portal = visible_in_portal
    @editable_in_portal = editable_in_portal
    @required_in_portal = required_in_portal
    @tag = tag
    @removable = removable
    @system_field_options = system_field_options
    @custom_field_options = custom_field_options
  end

  def regexp_for_validation
    if @regexp_for_validation.nil? || @type != 'regexp'
      return 'null'
    else
      return "\"#{@regexp_for_validation}\""
    end
  end

  def tag
    if @tag.nil?
      return 'null'
    else
      return "\"#{@tag}\""
    end
  end
end

class Trigger
  attr_reader :id, :title, :active, :actions, :conditions, :position

  def initialize id, title, active, actions, conditions, position
    @id = id
    @title = title
    @active = active
    @actions = actions
    @conditions = conditions
    @position = position
  end
end