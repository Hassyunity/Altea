module ApplicationHelper
  AREA_META = {
    "work" => { label: "Work", subtitle: "Vie professionnelle", icon: "◈" },
    "personal" => { label: "Personal", subtitle: "Vie personnelle", icon: "◆" }
  }.freeze

  STATUS_LABELS = {
    "todo" => "À faire", "doing" => "En cours", "done" => "Terminé",
    "active" => "Actif", "paused" => "En pause"
  }.freeze

  PRIORITY_LABELS = {
    "low" => "Basse", "normal" => "Normale", "high" => "Haute", "urgent" => "Urgente"
  }.freeze

  def area_meta(area)
    AREA_META.fetch(area)
  end

  def status_label(value)
    STATUS_LABELS.fetch(value, value.to_s.humanize)
  end

  def priority_label(value)
    PRIORITY_LABELS.fetch(value, value.to_s.humanize)
  end

  # Sidebar entries for one life area.
  def area_sections(area)
    [
      { name: "Tableau de bord", path: dashboard_path(life_area: area), icon: "▤", match: :exact },
      { name: "Projets", path: projects_path(life_area: area), icon: "▧" },
      { name: "Tâches", path: tasks_path(life_area: area), icon: "✓" },
      { name: "Notes", path: notes_path(life_area: area), icon: "✎" }
    ]
  end

  # The dashboard path ("/work") must not light up for "/work/tasks", hence :exact.
  def nav_active?(path, match: :prefix)
    return request.path == path if match == :exact

    request.path == path || request.path.start_with?("#{path}/")
  end

  def due_label(date)
    return nil if date.blank?

    case (date - Date.current).to_i
    when 0 then "Aujourd'hui"
    when 1 then "Demain"
    when -1 then "Hier"
    else date.strftime("%d/%m/%Y")
    end
  end

  # ALTEA's face: one canonical portrait, used in the sidebar, the intro and the hero.
  def altea_avatar
    "altea/avatar.png"
  end

  # Ambient artwork set, kept for backgrounds and future screens.
  def altea_portrait(index = 1)
    "altea/altea-0#{index}.png"
  end

  # Lines ALTEA speaks on first entry, in order.
  def altea_intro_lines
    [
      "Bonjour.",
      "Je suis ALTEA.",
      "Votre assistante de vie, professionnelle et personnelle.",
      "Je garde un œil sur vos projets, vos tâches et vos notes."
    ]
  end
end
