defmodule MerkleTree.Node do
  import Crypto

  defstruct [:hash, :left, :right]

  @type t :: %MerkleTree.Node{
    hash:  Crypto.hash256,
    left:  t | Leaf.t | nil,
    right: t | Leaf.t | nil
  }

  def new(left, nil), do: %MerkleTree.Node{hash: sha256x2(left.hash <> left.hash), left: left, right: nil}
  def new(left, right), do: %MerkleTree.Node{hash: sha256x2(left.hash <> right.hash), left: left, right: right}
end
