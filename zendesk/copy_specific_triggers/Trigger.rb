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