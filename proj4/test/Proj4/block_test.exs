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
    size_test: 40*4 + 1 + (1 + 64 + 64 + 4 + 3 + 2), #txs + tx_count + (ver + prev_hash + root + time + diff + nonce)
    genesis_header: %Block.BlockHeader{
          version: Application.get_env(:proj4, :block_version),
          previous_hash: "000000000000000000000000000000000000000000000000000000000000000",
          merkle_root: "4a5e1e4baab89f3a32518a88c31bc87f618f76673e2cc77ab2127b7afdeda33b",
          timestamp: 1231006505,
          difficulty: 486604799,
          nonce: 2083236893
        },
    genesis_hash: "000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f"
	 }
  end

  test "Use case when creating a block object", %{tx_test: tx_test, prev_hash: prev_hash, nonce: nonce, size_test: size_test} do
    tree = MerkleTree.makeMerkle(tx_test)
    block = Block.createBlock(tx_test, tree.root.hash_value, prev_hash, nonce)
    assert(block.block_size == size_test)
    assert(block.transactions == tx_test)
    assert([block.block_header.previous_hash] == prev_hash)
    assert(block.block_header.merkle_root == tree.root.hash_value)
  end

  test "Generate a block hash for the Genesis block", %{genesis_header: genesis_header, genesis_hash: genesis_hash} do
    assert(Block.generate_block_hash(genesis_header) == genesis_hash)
  end

  test "Successfully verifying a block", %{tx_test: tx_test, prev_hash: prev_hash, nonce: nonce} do
    tree = MerkleTree.makeMerkle(tx_test)
    block = Block.createBlock(tx_test, tree.root.hash_value, prev_hash, nonce)
    block_hash = Block.generate_block_hash(block.block_header)
    assert(Block.verifyBlock(block, block_hash))
  end

  test "Fail block verification on difficulty", %{tx_test: tx_test, prev_hash: prev_hash, nonce: nonce} do
    tree = MerkleTree.makeMerkle(tx_test)
    block = Block.createBlock(tx_test, tree.root.hash_value, prev_hash, nonce)
    block = Block.setDifficulty(block, 0xFFFF00)
    block_hash = Block.generate_block_hash(block.block_header)
    assert_raise(Block.DiffError, fn () -> Block.verifyBlock(block, block_hash, [:diff]) end)
  end

  test "Fail block verification on block hash", %{tx_test: tx_test, prev_hash: prev_hash, nonce: nonce} do
    tree = MerkleTree.makeMerkle(tx_test)
    block = Block.createBlock(tx_test, tree.root.hash_value, prev_hash, nonce)
    block_hash = Block.generate_block_hash(block.block_header) <> "0"
    assert_raise(Block.BlockHashError, fn () -> Block.verifyBlock(block, block_hash, [:block]) end)
  end

  test "Fail block verification on merkle root hash", %{tx_test: tx_test, prev_hash: prev_hash, nonce: nonce} do
    tree = MerkleTree.makeMerkle(tx_test)
    block = Block.createBlock(tx_test, tree.root.hash_value <> "0", prev_hash, nonce)
    block_hash = Block.generate_block_hash(block.block_header)
    assert_raise(Block.MerkleRootError, fn () -> Block.verifyBlock(block, block_hash, [:merkle]) end)
  end

end
