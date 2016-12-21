class Agent
  attr_reader :name, :email, :id, :groups

  def initialize(name, id, groups)
    @name = name
    @email = email
    @user_id = id
    @groups = groups
  end

end


class Group
  attr_reader :name, :id
  attr_writer :name, :id

  def initialize(name, group_id)
    @name = name
    @group_id = group_id
  end

end