defmodule CaltarWeb.Gettext do
  use Gettext.Backend, otp_app: :caltar

  defmacro __using__(_) do
    quote do
      use Gettext, backend: CaltarWeb.Gettext
    end
  end
end
