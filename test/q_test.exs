defmodule QTest do
  use ExUnit.Case
  doctest Q

  test "greets the world" do
    assert Q.new()
  end

  test "run/5" do
    defmodule TestRun do
      def test(changes, params) do
        assert changes === %{init: :test}
        assert params === :hello

        {:ok, 1}
      end
    end

    result =
      Q.new()
      |> Q.put(:init, :test)
      |> Q.run(:test_fun, TestRun, :test, [:hello])
      |> Q.exec()

    assert {:ok, %{init: :test, test_fun: 1}} = result
  end

  test "results are aggregated" do
    result =
      Q.new()
      |> Q.put(:init, :test)
      |> Q.run(:read, fn _ -> {:ok, :read} end)
      |> Q.run(:write, fn %{read: _read} -> {:ok, :write} end)
      |> Q.exec()

    assert {:ok, %{init: :test, read: :read, write: :write}} = result
  end

  test "handles error" do
    result =
      Q.new()
      |> Q.put(:init, :test)
      |> Q.run(:read, fn _ -> {:ok, :read} end)
      |> Q.run(:write, fn %{read: _read} -> {:error, :write_failed} end)
      |> Q.exec()

    assert {:error, :write, :write_failed, %{init: :test, read: :read}} = result
  end

  describe "to_list/1" do
    test "returns a list of operations" do
      que =
        Q.new()
        |> Q.put(:init, :test)
        |> Q.run(:read, fn _ -> {:ok, :read} end)
        |> Q.run(:write, fn %{read: _read} -> {:ok, :write} end)

      assert [
               {:init, {:put, :test}},
               {:read, {:run, _}},
               {:write, {:run, _}}
             ] = Q.to_list(que)
    end
  end
end
