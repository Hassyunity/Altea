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

# --- Banque (espace personnel), montants en ariary -------------------------

accounts = {
  courant: Account.find_or_create_by!(name: "Compte courant", life_area: "personal") do |a|
    a.kind = "bank"
    a.institution = "BNI"
    a.opening_balance_cents = 2_500_000_00
    a.color = "cyan"
  end,
  epargne: Account.find_or_create_by!(name: "Épargne", life_area: "personal") do |a|
    a.kind = "bank"
    a.institution = "BOA"
    a.opening_balance_cents = 8_000_000_00
    a.color = "azure"
  end,
  mvola: Account.find_or_create_by!(name: "MVola perso", life_area: "personal") do |a|
    a.kind = "mvola"
    a.institution = "Telma"
    a.opening_balance_cents = 350_000_00
    a.color = "emerald"
  end,
  coffre: Account.find_or_create_by!(name: "Coffre-fort maison", life_area: "personal") do |a|
    a.kind = "safe"
    a.opening_balance_cents = 1_200_000_00
    a.color = "amber"
  end,
  especes: Account.find_or_create_by!(name: "Portefeuille", life_area: "personal") do |a|
    a.kind = "cash"
    a.opening_balance_cents = 150_000_00
    a.color = "rose"
  end
}

operations = [
  { description: "Salaire du mois", account: accounts[:courant], kind: "income",
    amount_cents: 3_500_000_00, category: "Salaire", days_ago: 12 },
  { description: "Loyer", account: accounts[:courant], kind: "expense",
    amount_cents: 800_000_00, category: "Logement", days_ago: 11 },
  { description: "Facture JIRAMA", account: accounts[:courant], kind: "expense",
    amount_cents: 145_000_00, category: "Factures", days_ago: 9 },
  { description: "Courses du marché", account: accounts[:especes], kind: "expense",
    amount_cents: 95_000_00, category: "Alimentation", days_ago: 6 },
  { description: "Provisions supermarché", account: accounts[:courant], kind: "expense",
    amount_cents: 240_000_00, category: "Alimentation", days_ago: 4 },
  { description: "Carburant", account: accounts[:courant], kind: "expense",
    amount_cents: 120_000_00, category: "Transport", days_ago: 3 },
  { description: "Crédit téléphone", account: accounts[:mvola], kind: "expense",
    amount_cents: 20_000_00, category: "Téléphone & Internet", days_ago: 2 },
  { description: "Consultation médicale", account: accounts[:mvola], kind: "expense",
    amount_cents: 60_000_00, category: "Santé", days_ago: 1 },
  { description: "Mise au coffre", account: accounts[:courant], kind: "transfer",
    transfer_account: accounts[:coffre], amount_cents: 500_000_00, days_ago: 10 },
  { description: "Approvisionnement MVola", account: accounts[:courant], kind: "transfer",
    transfer_account: accounts[:mvola], amount_cents: 100_000_00, days_ago: 8 }
]

operations.each do |attrs|
  Transaction.find_or_create_by!(description: attrs[:description], account: attrs[:account]) do |operation|
    operation.assign_attributes(attrs.except(:description, :account, :days_ago))
    operation.occurred_on = Date.current - attrs[:days_ago]
  end
end

puts "Seed: #{Project.count} projets, #{Task.count} tâches, #{Note.count} notes, " \
     "#{Account.count} comptes, #{Transaction.count} opérations."
