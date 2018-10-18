defmodule Generator do
  @moduledoc "Generates test data for ErlangTermFormat.jl."
  @dir __DIR__ |> Path.join("..") |> Path.join("data")

  File.rm_rf(@dir)
  File.mkdir(@dir)

  def writebin(x, label) do
    path = Path.join(@dir, "#{label}-#{:rand.uniform()}.etf")
    term = :erlang.term_to_binary(x)
    File.write(path, term)
  end

  def gensuite do
    writebin(99, "SMALL_INTEGER")
    writebin(999999999, "INTEGER")
    writebin(1.2345, "NEW_FLOAT")
    writebin(:hello, "ATOM")
    writebin(round(:math.pow(3, 33)), "SMALL_BIG")
  end
end

Generator.gensuite()
