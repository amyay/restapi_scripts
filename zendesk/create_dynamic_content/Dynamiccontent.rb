class Dynamiccontent
  attr_reader :name, :default_locale, :variant_1, :variant_26, :variant_47, :variant_9, :variant_81, :variant_77, :variant_1307, :variant_10

  def initialize name, default_locale, variant_1, variant_26, variant_47, variant_9, variant_81, variant_77, variant_1307, variant_10
    @name = name
    @default_locale = default_locale
    @variant_1 = variant_1
    @variant_26 = variant_26
    @variant_47 = variant_47
    @variant_9 = variant_9
    @variant_81= variant_81
    @variant_77 = variant_77
    @variant_1307 = variant_1307
    @variant_10 = variant_10
  end
end

# locale ID's
# 1  - en-US
# 26 - vi (Vietnamese)
# 47 - fil (Filipino)
# 9  - zh-TW (Traditional Chinese)
# 81 - th (Thai)
# 77 - id (Indonesian)
# 1307 - ms (Malay)
# 10 - zh-CN (Simplified Chinese)

