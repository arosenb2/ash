defmodule Ash.Test.ReactorCreateTest do
  @moduledoc false
  use ExUnit.Case, async: true

  defmodule Post do
    @moduledoc false
    use Ash.Resource, data_layer: Ash.DataLayer.Ets

    ets do
      private? true
    end

    attributes do
      uuid_primary_key :id
      attribute :title, :string, allow_nil?: false
      attribute :sub_title, :string
    end

    actions do
      defaults [:create, :read, :update, :destroy]
    end
  end

  defmodule Api do
    @moduledoc false
    use Ash.Api

    resources do
      resource Post
    end
  end

  defmodule CreatePostReactor do
    @moduledoc false
    use Reactor, extensions: [Ash.Reactor]

    ash do
      default_api Api
    end

    input :title
    input :sub_title

    create :create_post, Post, :create do
      inputs(%{title: input(:title)})

      inputs %{sub_title: input(:sub_title)} do
        transform fn inputs -> %{sub_title: String.upcase(inputs.sub_title)} end
      end
    end

    # step :create_post do
    #   run fn _ -> {:ok, "Hello World"} end
    # end

    return :create_post
  end

  test "it can create a post" do
    CreatePostReactor.reactor()
    |> Map.get(:plan)
    |> Graph.vertices()
    |> IO.inspect()

    assert {:error, [wat]} =
             Reactor.run(CreatePostReactor, %{title: "Title", sub_title: "Sub-title"})

    raise wat
  end
end
