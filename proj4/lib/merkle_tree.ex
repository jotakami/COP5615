defmodule MerkleTree do
  @moduledoc """
  This module represents a merkle tree which produces the root hash stored in a
  block in the bitcoin bloackchain. A merkle tree is a data structure represented
  as a binary tree with hashes. The merkle tree consists of the hashes of transactions
  as leaf nodes, which in turn are hashed to create internal nodes in the tree structure.
  The root hash of the tree resides on the top-level of the tree. Transactions can be
  validated as a part of the tree through building the merkle path up to the root hash.

  """

  defstruct [:root]

  @type root :: MerkleTree.Node.t
  @type t :: %MerkleTree{
    root: root
  }

  @doc """
  Hash function for creating node hashes from data.
  Uses SHA256 hash alogrithm.
  """
  @spec hash(String.t) :: String.t
  defp hash(data) do
    :crypto.hash(:sha256, data) |> Base.encode16(case: :lower)
  end


  @spec is_correct_power([String.t, ...]) :: Boolean.t
  defp is_correct_power(data) do
    len = length(data)
    :math.ceil(:math.log2(len)) == :math.floor(:math.log2(len))
  end

  @spec makeMerkle([String.t, ...]) :: MerkleTree.Node.t
  def makeMerkle(transactions) do
    if (transactions == []), do: raise FunctionClauseError
    unless is_correct_power(transactions), do: raise MerkleTree.PowerError

    root = transactions
    |> Enum.map(fn (tx) ->
      %MerkleTree.Node{
        hash_value: hash(tx),
        height: 0,
        children: []
      } end) |> generate_tree(1)
      %MerkleTree{root: root}
  end

  @doc """
  Recursively build the tree until only root node is left.
  Builds the tree on a level by level basis.
  """
  @spec makeMerkle([MerkleTree.Node.t, ...]) :: MerkleTree.Node.t
  defp generate_tree([root], _), do: root
  defp generate_tree(nodes, height) do
    parent_nodes = nodes
    |> Enum.chunk_every(2)
    |> Enum.map(fn(node_pair) ->
      concat_hash = node_pair |>
      Enum.map(&(&1.hash_value))
      |> List.flatten()
      |> Enum.chunk_every(2)
      |> Enum.map(fn [h1, h2] -> hash(h1 <> h2) end)
        %MerkleTree.Node{
          hash_value: concat_hash,
          height: height,
          children: %{:left => Enum.at(node_pair, 0), :right => Enum.at(node_pair, 1)}
        }
    end)
    generate_tree(parent_nodes, height+1)
  end


end