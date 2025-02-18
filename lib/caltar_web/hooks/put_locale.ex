defmodule CaltarWeb.Hooks.PutLocale do
  def on_mount(:default, _params, _session, socket) do
    Gettext.put_locale(CaltarWeb.Gettext, Caltar.Application.locale())
    {:cont, socket}
  end
end
