# Demo content so both areas look alive on first boot. Idempotent: keyed on names/titles.

projects = {
  refonte: Project.find_or_create_by!(name: "Refonte plateforme client", life_area: "work") do |p|
    p.description = "Migration de l'espace client vers la nouvelle stack, livraison par lots."
    p.color = "cyan"
  end,
  recrutement: Project.find_or_create_by!(name: "Recrutement dev backend", life_area: "work") do |p|
    p.description = "Sourcing, entretiens techniques et onboarding du prochain profil."
    p.color = "azure"
  end,
  appartement: Project.find_or_create_by!(name: "Aménagement appartement", life_area: "personal") do |p|
    p.description = "Salon puis bureau : peinture, rangements, câblage."
    p.color = "amber"
  end,
  forme: Project.find_or_create_by!(name: "Remise en forme", life_area: "personal") do |p|
    p.description = "Trois séances par semaine, suivi du sommeil."
    p.color = "emerald"
    p.status = "active"
  end
}

tasks = [
  { title: "Préparer la démo client de vendredi", life_area: "work", project: projects[:refonte],
    priority: "high", due_on: Date.current + 2, status: "doing" },
  { title: "Relire les specs du module facturation", life_area: "work", project: projects[:refonte],
    priority: "normal", due_on: Date.current },
  { title: "Répondre aux candidatures en attente", life_area: "work", project: projects[:recrutement],
    priority: "urgent", due_on: Date.current - 1 },
  { title: "Planifier les entretiens techniques", life_area: "work", project: projects[:recrutement],
    priority: "normal", due_on: Date.current + 5 },
  { title: "Faire le point budget trimestre", life_area: "work", priority: "low" },
  { title: "Archiver les tickets clos", life_area: "work", status: "done", priority: "low" },

  { title: "Commander la peinture du salon", life_area: "personal", project: projects[:appartement],
    priority: "normal", due_on: Date.current + 1 },
  { title: "Monter les étagères du bureau", life_area: "personal", project: projects[:appartement],
    priority: "low", due_on: Date.current + 9 },
  { title: "Séance course — 5 km", life_area: "personal", project: projects[:forme],
    priority: "normal", due_on: Date.current },
  { title: "Prendre rendez-vous chez le dentiste", life_area: "personal", priority: "high",
    due_on: Date.current - 3 },
  { title: "Réserver les billets de train", life_area: "personal", status: "done", priority: "normal" }
]

tasks.each do |attrs|
  Task.find_or_create_by!(title: attrs[:title], life_area: attrs[:life_area]) do |task|
    task.assign_attributes(attrs.except(:title, :life_area))
  end
end

notes = [
  { title: "Notes de la réunion de cadrage", life_area: "work", project: projects[:refonte], pinned: true,
    body: "Périmètre validé pour le lot 1.\n\nPoints ouverts :\n- SSO à confirmer avec l'équipe sécurité\n- Reprise des données : fenêtre de bascule le week-end\n- Budget support à revoir en fin de mois" },
  { title: "Grille d'entretien technique", life_area: "work", project: projects[:recrutement],
    body: "1. Parcours et contexte des projets récents\n2. Exercice de lecture de code\n3. Conception d'API\n4. Questions du candidat" },
  { title: "Idées déco salon", life_area: "personal", project: projects[:appartement], pinned: true,
    body: "Teinte bleu nuit sur le mur du fond, étagères bois clair, éclairage indirect derrière le canapé." },
  { title: "Objectifs du trimestre", life_area: "personal",
    body: "Dormir 7 h en moyenne, trois séances de sport par semaine, un week-end hors de la ville par mois." }
]

notes.each do |attrs|
  Note.find_or_create_by!(title: attrs[:title], life_area: attrs[:life_area]) do |note|
    note.assign_attributes(attrs.except(:title, :life_area))
  end
end

puts "Seed: #{Project.count} projets, #{Task.count} tâches, #{Note.count} notes."
