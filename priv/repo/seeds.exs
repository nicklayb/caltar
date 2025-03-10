if not Caltar.Storage.calendar_slug_exists?("main") do
  %{name: "Main", display_mode: "relative:1:1"}
  |> Caltar.Storage.Calendar.changeset()
  |> Caltar.Repo.insert!()
end
