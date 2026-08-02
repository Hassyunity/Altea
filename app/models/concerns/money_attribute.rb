# Amounts are stored as integer minor units (x100) to keep arithmetic exact.
# `money_attribute :amount` exposes a decimal `amount` accessor for forms,
# accepting "1 500 000", "1500000,50" or "1500000.50".
module MoneyAttribute
  extend ActiveSupport::Concern

  class_methods do
    def money_attribute(name)
      cents = :"#{name}_cents"

      define_method(name) do
        value = public_send(cents)
        value.nil? ? nil : value.to_d / 100
      end

      define_method(:"#{name}=") do |input|
        if input.blank?
          public_send(:"#{cents}=", nil)
        else
          normalized = input.to_s.gsub(/[[:space:]]/, "").tr(",", ".")
          public_send(:"#{cents}=", (normalized.to_d * 100).round)
        end
      rescue ArgumentError
        public_send(:"#{cents}=", nil)
      end
    end
  end
end
