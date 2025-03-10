defmodule CaltarWeb.Settings.Calendar.CreateOrUpdateProvider do
  alias Caltar.Storage.Configuration.Formula1
  use CaltarWeb, :live_component

  alias Caltar.Calendar.Provider.SportSchedule, as: SportProvider
  alias Caltar.Storage
  alias Caltar.Storage.Configuration.Birthdays
  alias Caltar.Storage.Configuration.Icalendar
  alias Caltar.Storage.Configuration.Recurring
  alias Caltar.Storage.Configuration.Sport
  alias Caltar.Storage.Provider

  alias CaltarWeb.Components.Form
  alias CaltarWeb.Components.Modal

  @sport_channels Map.keys(Sport.providers())
  @defaults [teams: [], sports: []]
  def mount(socket) do
    socket = assign(socket, @defaults)

    {:ok, socket}
  end

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign(:channels, [
        {gettext("Choose"), ""} | Enum.map(@sport_channels, &{Html.titleize(&1), &1})
      ])
      |> maybe_load_provider()

    {:ok, socket}
  end

  defp maybe_load_provider(%{assigns: %{provider_id: provider_id}} = socket) do
    case Storage.get_provider(provider_id) do
      {:ok, %Provider{} = provider} ->
        socket
        |> assign(:provider, provider)
        |> assign(:title, gettext("Update Provider"))
        |> assign(:submit, gettext("Update"))
        |> assign_form()

      _ ->
        socket
    end
  end

  defp maybe_load_provider(socket) do
    socket
    |> assign(:title, gettext("Create Provider"))
    |> assign(:submit, gettext("Create"))
    |> assign_form(%{color: Caltar.Color.random_pastel(:hex)})
  end

  defp assign_form(socket, params \\ %{})

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp assign_form(socket, params) do
    assign_form(socket, changeset(socket, params))
  end

  defp changeset(%{assigns: assigns}, params) do
    provider = Map.get(assigns, :provider, %Provider{})

    params =
      Box.Map.put_new_lazy(params, :configuration_type, fn ->
        provider
        |> Provider.configuration_type()
        |> to_string()
      end)

    Provider.changeset(provider, params)
  end

  def handle_event(
        "change",
        %{"_target" => ["provider", "configuration_type"], "provider" => provider_params},
        socket
      ) do
    params =
      case Map.get(provider_params, "configuration_type") do
        "" -> Map.delete(provider_params, "configuration")
        value -> Map.put(provider_params, "configuration", %{"__type__" => value})
      end

    socket = assign_form(socket, params)

    {:noreply, socket}
  end

  def handle_event(
        "change",
        %{
          "_target" => ["provider", "configuration", "sport"],
          "provider" =>
            %{"configuration" => %{"provider" => sport_provider, "sport" => sport_slug}} =
              provider_params
        },
        socket
      ) do
    socket =
      socket
      |> assign_form(provider_params)
      |> load_teams(sport_provider, sport_slug)

    {:noreply, socket}
  end

  def handle_event(
        "change",
        %{
          "_target" => ["provider", "configuration", "provider"],
          "provider" => %{"configuration" => %{"provider" => sport_provider}} = provider_params
        },
        socket
      ) do
    socket =
      socket
      |> assign_form(provider_params)
      |> load_sports(sport_provider)

    {:noreply, socket}
  end

  def handle_event("change", %{"provider" => provider_params}, socket) do
    socket = assign_form(socket, provider_params)

    {:noreply, socket}
  end

  def handle_event("save", %{"provider" => provider_params}, socket) do
    {use_case, params} = get_use_case(socket, provider_params)

    socket =
      case execute_use_case(socket, use_case, params) do
        {:ok, _} ->
          send(self(), :close_modal)
          socket

        {:error, :provider, %Ecto.Changeset{} = changeset, _} ->
          assign_form(socket, changeset)
      end

    {:noreply, socket}
  end

  defp load_sports(socket, "") do
    assign(socket, :sports, [])
  end

  defp load_sports(socket, sport_provider) do
    sports =
      Sport.providers()
      |> Map.fetch!(sport_provider)
      |> Enum.map(&{Html.titleize(&1), &1})
      |> then(&[{gettext("Choose"), ""} | &1])

    assign(socket, :sports, sports)
  end

  defp load_teams(socket, _, "") do
    assign(socket, :teams, [])
  end

  defp load_teams(socket, sport_provider_slug, sport_slug) do
    teams_options =
      case SportProvider.request_teams(sport_provider_slug, sport_slug) do
        {:ok, teams} ->
          Enum.map(teams, &{&1.full_name, &1.id})

        _ ->
          []
      end

    assign(socket, :teams, teams_options)
  end

  defp get_use_case(%{assigns: %{provider: %Provider{id: provider_id}}}, params) do
    {Caltar.Storage.UseCase.UpdateProvider, Box.Map.put(params, :provider_id, provider_id)}
  end

  defp get_use_case(_socket, params) do
    {Caltar.Storage.UseCase.CreateProvider, params}
  end

  def render(assigns) do
    configuration_types =
      Provider
      |> PolymorphicEmbed.types(:configuration)
      |> Enum.map(&{Html.titleize(&1), to_string(&1)})
      |> then(&[{gettext("Choose"), ""} | &1])

    assigns =
      assign(assigns, :configuration_types, configuration_types)

    ~H"""
    <div>
      <.form for={@form} class="relative" phx-change="change" phx-submit="save" phx-target={@myself}>
        <Modal.modal>
          <:header>
            {@title}
          </:header>
          <:body class="max-h-96 overflow-y-auto">
            <Form.hidden
              field={@form[:calendar_id]}
              name={@form[:calendar_id].name}
              value={@calendar_id}
            />
            <Form.text_input field={@form[:name]}>
              <:label>{gettext("Provider name")}</:label>
            </Form.text_input>
            <Form.color_input field={@form[:color]}>
              <:label>{gettext("Provider color")}</:label>
            </Form.color_input>
            <Form.select_input field={@form[:configuration_type]} options={@configuration_types}>
              <:label>{gettext("Provider type")}</:label>
            </Form.select_input>
            <PolymorphicEmbed.HTML.Component.polymorphic_embed_inputs_for
              :let={configuration_form}
              field={@form[:configuration]}
            >
              <Form.hidden
                field={configuration_form[:__type__]}
                name={configuration_form[:__type__].name}
                value={configuration_form[:__type__].value}
              />
              <.configuration_form
                form={configuration_form}
                type={PolymorphicEmbed.HTML.Helpers.source_module(configuration_form)}
                provider_name={@form[:name].value}
                channels={@channels}
                sports={@sports}
                teams={@teams}
              />
            </PolymorphicEmbed.HTML.Component.polymorphic_embed_inputs_for>
          </:body>
          <:footer class="text-right">
            <Form.button type={:submit} phx-target={@myself}>
              {@submit}
            </Form.button>
          </:footer>
        </Modal.modal>
      </.form>
    </div>
    """
  end

  defp configuration_form(%{type: Birthdays} = assigns) do
    ~H"""
    <Form.textarea field={@form[:birthdays_input]} placeholder="Neil Peart:1952-09-12">
      <:label>{gettext("Birthdays")}</:label>
    </Form.textarea>
    """
  end

  @icons ~w(gear compost recycle trash)a
  defp configuration_form(%{type: Recurring} = assigns) do
    icons =
      @icons
      |> Enum.map(&{Html.titleize(&1), to_string(&1)})
      |> then(&[{gettext("Choose"), ""} | &1])

    every_units =
      Recurring.units()
      |> Enum.map(&{Html.titleize(&1), to_string(&1)})
      |> then(&[{gettext("Choose"), ""} | &1])

    assigns =
      assigns
      |> assign(:icons, icons)
      |> assign(:every_units, every_units)

    ~H"""
    <Form.hidden field={@form[:name]} value={@provider_name} />
    <Form.element name={:dates}>
      <:label>{gettext("From / To")}</:label>
      <div class="flex">
        <Form.text_input
          field={@form[:from_date]}
          placeholder={gettext("From")}
          element_class="mb-0 [&>label]:hidden"
        />
        <Form.text_input
          field={@form[:to_date]}
          placeholder={gettext("To (optional)")}
          element_class="mb-0 [&>label]:hidden"
        />
      </div>
    </Form.element>
    <Form.element name={:every}>
      <:label>{gettext("Every")}</:label>
      <div class="flex">
        <Form.text_input field={@form[:every_count]} element_class="mb-0 [&>label]:hidden" />
        <Form.select_input
          field={@form[:every_unit]}
          options={@every_units}
          element_class="mb-0 [&>label]:hidden"
        />
      </div>
    </Form.element>
    <Form.element name={:icon}>
      <div class="flex items-center">
        <Form.select_input field={@form[:icon]} options={@icons} element_class="w-full">
          <:label>{gettext("Icon")}</:label>
        </Form.select_input>

        <%= if @form[:icon].value not in ["", nil] do %>
          <div class="text-gray-200 ml-3">
            <Components.Icon.icon icon={@form[:icon].value} width={35} height={35} />
          </div>
        <% end %>
      </div>
    </Form.element>
    """
  end

  defp configuration_form(%{type: Sport} = assigns) do
    ~H"""
    <Form.select_input field={@form[:provider]} options={@channels} element_class="w-full">
      <:label>{gettext("Sport channel")}</:label>
    </Form.select_input>
    <%= if Enum.any?(@sports) do %>
      <Form.select_input field={@form[:sport]} options={@sports} element_class="w-full">
        <:label>{gettext("Sport")}</:label>
      </Form.select_input>
    <% end %>
    <%= if Enum.any?(@teams) do %>
      <Form.select_input field={@form[:team_id]} options={@teams} element_class="w-full">
        <:label>{gettext("Team")}</:label>
      </Form.select_input>
    <% end %>
    """
  end

  defp configuration_form(%{type: Formula1} = assigns) do
    assigns = assign(assigns, :parts, Formula1.parts())

    ~H"""
    <%= for {value, label} <- @parts do %>
      <Form.checkbox
        field={@form[:parts]}
        multiple={true}
        value={value}
        checked={to_string(value) in @form[:parts].value}
      >
        <:label>{label}</:label>
      </Form.checkbox>
    <% end %>
    """
  end

  defp configuration_form(%{type: Icalendar} = assigns) do
    ~H"""
    <Form.text_input field={@form[:url]}>
      <:label>{gettext("URL")}</:label>
    </Form.text_input>
    <Form.text_input field={@form[:icon]}>
      <:label>{gettext("Icon (optional)")}</:label>
    </Form.text_input>
    """
  end
end
