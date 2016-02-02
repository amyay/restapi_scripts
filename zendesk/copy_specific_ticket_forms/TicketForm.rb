class TicketForm
  attr_reader :id, :name, :raw_name, :display_name, :raw_display_name, :end_user_visible, :position, :ticket_field_ids, :active, :default, :in_all_brands, :restricted_brand_ids

  def initialize id, name, raw_name, display_name, raw_display_name, end_user_visible, position, ticket_field_ids, active, default, in_all_brands, restricted_brand_ids
    @id = id
    @name = name
    @raw_name = raw_name
    @display_name = display_name
    @raw_display_name = raw_display_name
    @end_user_visible = end_user_visible
    @position = position
    @ticket_field_ids = ticket_field_ids
    @active = active
    @default = default
    @in_all_brands = in_all_brands
    @restricted_brand_ids = restricted_brand_ids
  end
end