class OrganizationField
  attr_reader :type, :key, :title, :description, :active, :system, :custom_field_options

  def initialize type, key, title, description, active, system, regexp_for_validation, custom_field_options, tag
    @type = type
    @key = key
    @title = title
    @description = description
    @active = active
    @system = system
    @regexp_for_validation = regexp_for_validation
    @custom_field_options = custom_field_options
    @tag = tag
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

  def type
    if @type == 'dropdown'
      return 'tagger'
    else
      return @type
    end
  end

end