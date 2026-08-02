module MoneyHelper
  ACCOUNT_KINDS = {
    "bank" => { label: "Compte bancaire", icon: "▥" },
    "mvola" => { label: "MVola", icon: "◎" },
    "orange_money" => { label: "Orange Money", icon: "◉" },
    "airtel_money" => { label: "Airtel Money", icon: "◍" },
    "safe" => { label: "Coffre-fort", icon: "▦" },
    "cash" => { label: "Espèces", icon: "≡" }
  }.freeze

  TRANSACTION_KINDS = {
    "expense" => [ "Dépense", "Dépenses" ],
    "income" => [ "Revenu", "Revenus" ],
    "transfer" => [ "Virement", "Virements" ]
  }.freeze

  CURRENCY_UNITS = { "MGA" => "Ar", "EUR" => "€", "USD" => "$" }.freeze

  def account_kind_label(kind)
    ACCOUNT_KINDS.dig(kind, :label) || kind.to_s.humanize
  end

  def account_kind_icon(kind)
    ACCOUNT_KINDS.dig(kind, :icon) || "▥"
  end

  def transaction_kind_label(kind, plural: false)
    labels = TRANSACTION_KINDS[kind]
    return kind.to_s.humanize if labels.nil?

    plural ? labels.last : labels.first
  end

  # Ariary is used without decimals; other currencies keep two.
  def money(cents, currency = "MGA")
    return "—" if cents.nil?

    unit = CURRENCY_UNITS.fetch(currency, currency)
    precision = currency == "MGA" ? 0 : 2

    number_to_currency(cents.to_d / 100,
                       unit: unit, precision: precision,
                       delimiter: " ", separator: ",", format: "%n %u")
  end

  # Signed, coloured amount as seen from a given account. Outside any account,
  # a transfer moves money between my own accounts: neither in nor out.
  def signed_money(transaction, account_id: nil)
    if transaction.transfer? && account_id.nil?
      return tag.span(money(transaction.amount_cents, transaction.currency), class: "amount muted")
    end

    cents = account_id ? transaction.signed_cents_for(account_id) : default_sign(transaction)
    css = cents.negative? ? "amount--out" : "amount--in"
    prefix = cents.negative? ? "−" : "+"

    tag.span "#{prefix} #{money(cents.abs, transaction.currency)}", class: "amount #{css}"
  end

  # Rails ships English locale data only; the UI is French.
  MONTHS = %w[janvier février mars avril mai juin
              juillet août septembre octobre novembre décembre].freeze

  def month_label(date)
    "#{MONTHS[date.month - 1].capitalize} #{date.year}"
  end

  private

  def default_sign(transaction)
    transaction.income? ? transaction.amount_cents : -transaction.amount_cents
  end
end
