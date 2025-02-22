defmodule Caltar.Cldr do
  use Cldr,
    providers: [Cldr.Number, Cldr.Calendar, Cldr.DateTime],
    gettext: CaltarWeb.Gettext
end
