class Organization
  attr_reader :name, :shared_tickets, :shared_comments, :domain_names, :tags, :organization_fields

  def initialize name, shared_tickets, shared_comments, external_id, domain_names, details, notes, group_id, tags, organization_fields
    @name = name
    @shared_tickets = shared_tickets
    @shared_comments = shared_comments
    @external_id = external_id
    @domain_names = domain_names
    @details = details
    @notes = notes
    @group_id = group_id
    @tags = tags
    @organization_fields = organization_fields
  end

  def external_id
    if @external_id.nil?
      return 'null'
    else
      return "\"#{@external_id}\""
    end
  end

  def details
    if (@details.nil?) || (@details == "\"\"")
      return 'null'
    else
      tempdetails = @details.gsub("\n","\\n")
      tempdetails.gsub!("\r","\\r")
      return "\"#{tempdetails}\""
    end
  end

  def notes
    if (@notes.nil?) || (@notes == "\"\"")
      return 'null'
    else
      tempnotes = @notes.gsub("\n","\\n")
      tempnotes.gsub!("\r","\\r")
      return "\"#{tempnotes}\""
    end
  end

  def group_id
    if @group_id.nil?
      return 'null'
    else
      return "#{@group_id}"
    end
  end

end