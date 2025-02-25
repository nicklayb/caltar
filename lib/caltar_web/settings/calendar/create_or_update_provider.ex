defmodule CaltarWeb.Settings.Calendar.CreateOrUpdateProvider do
  use CaltarWeb, :live_component

  alias Caltar.Storage.Configuration.Recurring
  alias Caltar.Storage.Configuration.Icalendar
  alias Caltar.Storage
  alias Caltar.Storage.Configuration.Birthdays
  alias Caltar.Storage.Provider
  alias CaltarWeb.Components.Form
  alias CaltarWeb.Components.Modal

  @defaults []
  def mount(socket) do
    socket = assign(socket, @defaults)

    {:ok, socket}
  end

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
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
    assigns
    |> Map.get(:provider, %Provider{})
    |> Provider.changeset(params)
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
    <Form.checkbox
      field={@form[:is_marker]}
      value="true"
      checked={@form[:is_marker].value |> IO.inspect(label: "Checked") == true}
    >
      <:label>{gettext("As Marker?")}</:label>
    </Form.checkbox>
    <%= if @form[:is_marker].value do %>
      <Form.element name={:every}>
        <:label>{gettext("Every")}</:label>
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
    <% end %>
    """
  end

  defp configuration_form(%{type: Icalendar} = assigns) do
    ~H"""
    <Form.text_input field={@form[:url]}>
      <:label>{gettext("URL")}</:label>
    </Form.text_input>
    """
  end
end
