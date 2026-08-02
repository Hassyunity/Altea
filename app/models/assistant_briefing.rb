# What ALTEA knows when you walk in: what is late, what is due, what is
# expensive. Reads the real data and turns it into spoken lines plus an
# actionable list. Built once per request and shared by the intro and the HUD.
class AssistantBriefing
  MAX_ITEMS = 5

  Item = Struct.new(:record, :tone, :headline, :detail, keyword_init: true)

  def initialize(now: Time.current)
    @now = now
  end

  # --- numbers -------------------------------------------------------------

  def overdue_tasks
    @overdue_tasks ||= open_tasks.overdue.by_urgency.includes(:project).to_a
  end

  def today_tasks
    @today_tasks ||= open_tasks.due_today.by_urgency.includes(:project).to_a
  end

  # High-stakes work with no deadline attached — easy to forget.
  def priority_tasks
    @priority_tasks ||= open_tasks.where(priority: %w[urgent high], due_on: nil)
                                  .order(created_at: :desc)
                                  .includes(:project)
                                  .to_a
  end

  def open_count = open_tasks.count

  def negative_accounts
    @negative_accounts ||= begin
      accounts = Account.in_area("personal").active.to_a
      balances = accounts.any? ? Account.balances_for(accounts) : {}
      accounts.select { |account| balances.fetch(account, 0).negative? }
    end
  end

  def month_expenses_cents
    @month_expenses_cents ||= Transaction.in_area("personal")
                                         .in_month(money_month)
                                         .expenses
                                         .sum(:amount_cents)
  end

  def money_month
    @money_month ||= Transaction.last_active_month("personal")
  end

  def has_money_data?
    Account.in_area("personal").active.exists?
  end

  # --- narration -----------------------------------------------------------

  def greeting
    case @now.hour
    when 5..11 then "Bonjour."
    when 12..17 then "Bon après-midi."
    when 18..22 then "Bonsoir."
    else "Vous veillez tard."
    end
  end

  def headline
    if overdue_tasks.any?
      "Vous avez #{count_phrase(overdue_tasks.size, 'tâche')} en retard."
    elsif today_tasks.any?
      "#{count_phrase(today_tasks.size, 'échéance')} #{today_tasks.size > 1 ? 'tombent' : 'tombe'} aujourd'hui."
    elsif priority_tasks.any?
      "#{count_phrase(priority_tasks.size, 'tâche')} prioritaire#{'s' if priority_tasks.size > 1} #{priority_tasks.size > 1 ? 'vous attendent' : 'vous attend'}."
    else
      "Rien d'urgent aujourd'hui. Tout est sous contrôle."
    end
  end

  # Lines shown on the welcome screen, in order. `lead` marks the two that
  # carry the message; `speech` is the spoken version — fuller sentences,
  # written to be heard rather than read.
  def intro_lines
    lines = [
      { text: greeting, lead: true, speech: spoken_greeting },
      { text: "Je suis ALTEA, votre assistante.", lead: false,
        speech: "Je suis Altéa, votre assistante personnelle." },
      { text: headline, lead: true, speech: spoken_headline }
    ]

    if (first = items.first&.record).is_a?(Task)
      lines << { text: "Le plus pressant : #{first.title}.", lead: false,
                 speech: "La plus pressante s'intitule : #{first.title}." }
    end

    if money_sentence
      lines << { text: money_sentence, lead: false, speech: spoken_money }
    end

    lines << { text: "Voici votre point de situation.", lead: false,
               speech: spoken_closing }
    lines
  end

  # One continuous paragraph, for when she is asked to read the briefing aloud.
  def spoken_briefing
    [ spoken_greeting, spoken_headline, spoken_money, spoken_closing ].compact.join(" ")
  end

  # Shorter rolling lines for the always-on sidebar HUD.
  def hud_lines
    lines = [ "#{greeting} Systèmes nominaux.", headline ]
    lines << "#{count_phrase(open_count, 'tâche')} ouverte#{'s' if open_count > 1} au total." if open_count.positive?
    lines << money_sentence if money_sentence
    lines << "Je reste à l'écoute. ⌘K pour me donner un ordre."
    lines
  end

  def money_sentence
    return @money_sentence if defined?(@money_sentence)

    @money_sentence =
      if negative_accounts.any?
        "Attention : #{negative_accounts.first.name} est à découvert."
      elsif has_money_data? && month_expenses_cents.positive?
        "Dépenses suivies sur #{month_name} : #{formatted_expenses}."
      end
  end

  # --- spoken variants -----------------------------------------------------
  #
  # Written for the ear: full sentences, connectors, no abbreviations, and
  # figures without thousand separators so the synthesiser reads them as
  # numbers rather than digit by digit.

  def spoken_greeting
    "#{greeting} Ravie de vous retrouver."
  end

  def spoken_headline
    if overdue_tasks.any?
      "Faisons le point ensemble. Vous avez #{count_phrase(overdue_tasks.size, 'tâche')} en retard, " \
        "et je vous conseille de commencer par là."
    elsif today_tasks.any?
      "Faisons le point ensemble. #{count_phrase(today_tasks.size, 'échéance')} " \
        "#{today_tasks.size > 1 ? 'arrivent' : 'arrive'} à terme aujourd'hui, et rien n'est en retard."
    elsif priority_tasks.any?
      "Faisons le point ensemble. #{count_phrase(priority_tasks.size, 'tâche')} " \
        "#{priority_tasks.size > 1 ? 'importantes vous attendent' : 'importante vous attend'}, sans date fixée."
    else
      "Faisons le point ensemble. Rien d'urgent aujourd'hui, tout est sous contrôle."
    end
  end

  def spoken_money
    return nil unless money_sentence

    if negative_accounts.any?
      "Un point de vigilance : le compte #{negative_accounts.first.name} est à découvert."
    else
      "Côté finances, vos dépenses de #{MoneyHelper::MONTHS[money_month.month - 1]} " \
        "s'élèvent à #{spoken_amount(month_expenses_cents)}."
    end
  end

  def spoken_closing
    if items.any?
      "Voici votre point de situation. Choisissez une priorité, ou réveillez la plateforme."
    else
      "Bon moment pour avancer sur le fond. Je vous laisse la main."
    end
  end

  # --- the actionable list -------------------------------------------------

  def items
    @items ||= build_items
  end

  def empty?
    items.empty?
  end

  private

  def open_tasks
    @open_tasks ||= Task.unfinished
  end

  def build_items
    list = []

    overdue_tasks.each do |task|
      list << Item.new(record: task, tone: "danger", headline: task.title,
                       detail: "En retard — #{french_date(task.due_on)}")
    end

    today_tasks.each do |task|
      list << Item.new(record: task, tone: "warn", headline: task.title,
                       detail: "Échéance aujourd'hui")
    end

    priority_tasks.each do |task|
      list << Item.new(record: task, tone: "accent", headline: task.title,
                       detail: "Priorité #{task.priority == 'urgent' ? 'urgente' : 'haute'}")
    end

    negative_accounts.each do |account|
      list << Item.new(record: account, tone: "danger", headline: account.name,
                       detail: "Compte à découvert")
    end

    list.first(MAX_ITEMS)
  end

  def count_phrase(count, noun)
    "#{count} #{count > 1 ? noun.pluralize : noun}"
  end

  def french_date(date)
    return "" if date.blank?

    days = (Date.current - date).to_i
    case days
    when 0 then "aujourd'hui"
    when 1 then "hier"
    when 2..6 then "il y a #{days} jours"
    else date.strftime("%d/%m/%Y")
    end
  end

  def month_name
    "#{MoneyHelper::MONTHS[money_month.month - 1]} #{money_month.year}"
  end

  # "1 480 000 Ar" reads as three separate numbers; "1480000 ariary" reads as one.
  def spoken_amount(cents)
    currency = Account.in_area("personal").active.first&.currency || "MGA"
    spoken_unit = { "MGA" => "ariary", "EUR" => "euros", "USD" => "dollars" }.fetch(currency, currency)
    amount = currency == "MGA" ? (cents / 100).round : (cents.to_d / 100).round(2)

    "#{amount} #{spoken_unit}"
  end

  def formatted_expenses
    cents = month_expenses_cents
    currency = Account.in_area("personal").active.first&.currency || "MGA"
    unit = MoneyHelper::CURRENCY_UNITS.fetch(currency, currency)
    precision = currency == "MGA" ? 0 : 2

    "#{ActiveSupport::NumberHelper.number_to_rounded(cents.to_d / 100, precision: precision, delimiter: ' ')} #{unit}"
  end
end
