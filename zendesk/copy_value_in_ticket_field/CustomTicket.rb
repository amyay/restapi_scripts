class CustomTicket
  attr_reader :id, :status, :tags, :ticket_form_id, :rea_from_field
  attr_writer :id, :status, :tags, :ticket_form_id, :rea_from_field

  def initialize id, status, tags, ticket_form_id
    @id = id
    @status = status
    @tags = tags
    @ticket_form_id = ticket_form_id
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