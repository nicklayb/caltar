%{name: "Main", display_mode: "relative:1:1"}
|> Caltar.Storage.Calendar.changeset()
|> Caltar.Repo.insert!()
