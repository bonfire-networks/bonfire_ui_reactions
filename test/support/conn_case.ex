defmodule Bonfire.UI.Reactions.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use MyApp.Web.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest

      import Bonfire.UI.Common.Testing.Helpers

      # import Phoenix.LiveViewTest
      # import Surface.LiveViewTest

      import PhoenixTest

      # import Bonfire.UI.Reactions.ConnCase
      import Bonfire.UI.Reactions.Test.ConnHelpers
      import Bonfire.UI.Reactions.Test.FakeHelpers
      import Bonfire.Common.Simulation
      import Bonfire.Me.Fake.Helpers

      use Bonfire.Common.Config
      use Bonfire.Common.Settings
      import Untangle
      use Arrows
      # alias Bonfire.UI.Reactions.Web.Router.Helpers, as: Routes

      # The default endpoint for testing
      @endpoint Application.compile_env!(:bonfire, :endpoint_module)

      @moduletag :ui
    end
  end

  setup tags do
    Bonfire.Common.Test.Interactive.setup_test_repo(tags)

    {:ok, []}
  end
end
