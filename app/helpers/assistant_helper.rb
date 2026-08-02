module AssistantHelper
  # One briefing per request, shared by the welcome screen and the sidebar HUD.
  def briefing
    @briefing ||= AssistantBriefing.new
  end

  # Rolling lines for the always-on HUD.
  def assistant_briefing
    briefing.hud_lines
  end

  # Identity card shown next to her projection on the welcome screen.
  def altea_profile
    {
      rows: [
        [ "Nom", "ALTEA" ],
        [ "Code", "ALT-01A" ],
        [ "Classe", "Assistante de vie" ],
        [ "Interface", "Projection holographique" ],
        [ "Domaines", "Work · Personal" ]
      ],
      gauges: [
        { left: "Réel", right: "Virtuel", value: 82 },
        { left: "Humain", right: "Machine", value: 64 },
        { left: "Présent", right: "Futur", value: 91 }
      ]
    }
  end

  def briefing_item_path(item)
    record = item.record

    case record
    when Task then task_path(record, life_area: record.life_area)
    when Account then account_path(record, life_area: record.life_area)
    else dashboard_path(life_area: life_area)
    end
  end

  def briefing_item_icon(item)
    item.record.is_a?(Account) ? "▥" : "✓"
  end

  def briefing_item_area(item)
    area_meta(item.record.life_area)[:label]
  end

  # Quick-jump entries for the command palette (⌘K).
  def command_palette_items
    items = []

    LifeAreaScoped::LIFE_AREAS.each do |area|
      label = area_meta(area)[:label]
      area_sections(area).each do |section|
        items << { label: "#{label} · #{section[:name]}", hint: "Aller à", url: section[:path], icon: section[:icon] }
      end
    end

    items.concat(
      [
        { label: "Nouvelle tâche", hint: "Créer", url: new_task_path(life_area: life_area), icon: "✓" },
        { label: "Nouveau projet", hint: "Créer", url: new_project_path(life_area: life_area), icon: "▧" },
        { label: "Nouvelle note", hint: "Créer", url: new_note_path(life_area: life_area), icon: "✎" },
        { label: "Nouvelle dépense", hint: "Banque", url: new_transaction_path(life_area: "personal", kind: "expense"), icon: "↑" },
        { label: "Nouveau revenu", hint: "Banque", url: new_transaction_path(life_area: "personal", kind: "income"), icon: "↓" },
        { label: "Nouveau virement", hint: "Banque", url: new_transaction_path(life_area: "personal", kind: "transfer"), icon: "⇅" },
        { label: "Nouveau compte", hint: "Banque", url: new_account_path(life_area: "personal"), icon: "▥" }
      ]
    )

    items
  end
end
