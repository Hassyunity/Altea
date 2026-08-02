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

  # Sidebar entries for one life area. Banking only shows under Personal;
  # the routes exist for both areas, so moving it is a one-line change.
  def area_sections(area)
    sections = [
      { name: "Tableau de bord", path: dashboard_path(life_area: area), icon: "▤", match: :exact },
      { name: "Projets", path: projects_path(life_area: area), icon: "▧" },
      { name: "Tâches", path: tasks_path(life_area: area), icon: "✓" },
      { name: "Notes", path: notes_path(life_area: area), icon: "✎" }
    ]

    if area == "personal"
      sections += [
        { name: "Comptes", path: accounts_path(life_area: area), icon: "▥" },
        { name: "Opérations", path: transactions_path(life_area: area), icon: "⇅" }
      ]
    end

    sections
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

  # Drop a portrait at app/assets/images/altea/holo.{png,webp,jpeg,jpg} and the
  # chamber projects it — chromatic ghosts, slices, scan lines, all reacting to
  # her voice. Without it she falls back to the figure drawn in code
  # (app/javascript/altea_figure.js).
  HOLO_CANDIDATES = %w[holo.png holo.webp holo.jpeg holo.jpg].freeze

  def altea_holo_image
    return @altea_holo_image if defined?(@altea_holo_image)

    name = HOLO_CANDIDATES.find { |file| Rails.root.join("app/assets/images/altea", file).exist? }
    @altea_holo_image = name && "altea/#{name}"
  end

  def altea_portrait(index = 1)
    "altea/altea-0#{index}.png"
  end

  def altea_avatar
    altea_holo_image || "altea/avatar.png"
  end
end
