defmodule Proj4.BlockTest do
  use ExUnit.Case

  setup do
    %{
	  tx_test: ["3e4bb40f066d195155e74eb0d26d644fbf5cab91",  #Transactions gathered by a miner.
                "ca3bce4f810bca6f68fcecd1b79627c06016f142",
                "ced1f2728fe4e928716a639cda1333af67eafeea",
                "0710260689d3f95eb18bdfb0235ffcf4cd728045"],
    prev_hash: [MerkleTree.hash("test")],  #Taken from the previous block in the chain
    nonce: 1337,  #This would be generated by the miner
    size_test: 40*4 + 1 + (1 + 64 + 64 + 4 + 1 + 2) #txs + tx_count + (ver + prev_hash + root + time + diff + nonce)
	 }
  end

  test "Use case when creating a block object", %{tx_test: tx_test, prev_hash: prev_hash, nonce: nonce, size_test: size_test} do
    tree = MerkleTree.makeMerkle(tx_test)
    block = Block.createBlock(tx_test, tree.root.hash_value, prev_hash, nonce)
    assert(block.block_size == size_test)
    assert(block.transactions == tx_test)
    assert(block.block_header.previous_hash == prev_hash)
    assert(block.block_header.merkle_root == tree.root.hash_value)
  end

  test "Successfully verifying a block", %{tx_test: tx_test, prev_hash: prev_hash, nonce: nonce, size_test: size_test} do
    tree = MerkleTree.makeMerkle(tx_test)
    block = Block.createBlock(tx_test, tree.root.hash_value, prev_hash, nonce)
  end

  #TODO Case when block verification fails and implement exception handling


end
