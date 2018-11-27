# defmodule Proj4.BlockTest do
#   use ExUnit.Case
#   @moduledoc """
#   This module defines a test for operations and functions in 'block.ex'.
#   """
#
#   setup do
#     %{
#     tx_test: ["c5246e478e0a319c099f94fe8e5b8c7b767a017f55408ebde477d0578659b4a8",  #Transactions gathered by a miner.
#                 "9ac0240b5e74ebaf38efa72e105cfeb06ee119dae56954dbd4f76cd790c738a5",
#                 "f25a13422d5cc7bb4331607502360cba53ceb6977623b3b4759fe96e42fdb1c8",
#                 "ce249be4a7f827ebccf51beb3d4cc919ee03b2aa51e4a3444142568d46a31a8a"],
#     prev_hash: [MerkleTree.hash("test")],  #Taken from the previous block in the chain
#     nonce: 1337,  #This would be generated by the miner
#     size_test: 64*4 + 1 + (1 + 64 + 64 + 4 + 3 + 2), #txs + tx_count + (ver + prev_hash + root + time + diff + nonce)
#     genesis_header: %Block.BlockHeader{
#           version: Application.get_env(:proj4, :block_version),
#           previous_hash: "000000000000000000000000000000000000000000000000000000000000000",
#           merkle_root: "4a5e1e4baab89f3a32518a88c31bc87f618f76673e2cc77ab2127b7afdeda33b",
#           timestamp: 1231006505,
#           difficulty: 486604799,
#           nonce: 2083236893
#         },
#     genesis_hash: "000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f"
# 	 }
#   end
#
#   @doc """
#   This test creates a block and checks that all values are set correctly in it.
#   """
#   test "Use case when creating a block object", %{tx_test: tx_test, prev_hash: prev_hash, nonce: nonce, size_test: size_test} do
#     tree = MerkleTree.makeMerkle(tx_test)
#     block = Block.createBlock(tx_test, tree.root.hash_value, prev_hash, nonce)
#     assert(block.block_size == size_test)
#     assert(block.transactions == tx_test)
#     assert([block.block_header.previous_hash] == prev_hash)
#     assert(block.block_header.merkle_root == tree.root.hash_value)
#   end
#
#   @doc """
#   This test creates and compares a block hash for the genesis block of the original bitcoin protocol.
#   The test serves as proof of correctness according to the protocol.
#   """
#   test "Generate a block hash for the Genesis block", %{genesis_header: genesis_header, genesis_hash: genesis_hash} do
#     assert(Block.generate_block_hash(genesis_header) == genesis_hash)
#   end
#
#   @doc """
#   Tests operation for verification of a block with a low difficulty. The verification is done in
#   full mode, which checks difficulty, the block hash, and checks the merkle root.
#   """
#   test "Successfully verifying a block", %{tx_test: tx_test, prev_hash: prev_hash, nonce: nonce} do
#     tree = MerkleTree.makeMerkle(tx_test)
#     block = Block.createBlock(tx_test, tree.root.hash_value, prev_hash, nonce)
#     block = Block.setDifficulty(block, 0xFFFFFF)
#     block_hash = Block.generate_block_hash(block.block_header)
#     assert(Block.verifyBlock(block, block.block_header, block_hash))
#   end
#
#   @doc """
#   This tests verifies that a failed verification is done according to fixed behaviour. An error should be
#   raised as the created bloch hash will be inaccurate according to a higher set difficulty for this test.
#   """
#   test "Fail block verification on difficulty", %{tx_test: tx_test, prev_hash: prev_hash, nonce: nonce} do
#     tree = MerkleTree.makeMerkle(tx_test)
#     block = Block.createBlock(tx_test, tree.root.hash_value, prev_hash, nonce)
#     block = Block.setDifficulty(block, 0xFFFF00)
#     block_hash = Block.generate_block_hash(block.block_header)
#     assert_raise(Block.DiffError, fn () -> Block.verifyBlock(block, block.block_header, block_hash, [:diff]) end)
#   end
#
#   @doc """
#   This test tests that an error is thrown when the block hash is inaccurate. Hence, even if the hash matches
#   the difficulty it doesn't mean the block hash is correct.
#   """
#   test "Fail block verification on block hash", %{tx_test: tx_test, prev_hash: prev_hash, nonce: nonce} do
#     tree = MerkleTree.makeMerkle(tx_test)
#     block = Block.createBlock(tx_test, tree.root.hash_value, prev_hash, nonce)
#     block_hash = Block.generate_block_hash(block.block_header) <> "0"
#     assert_raise(Block.BlockHashError, fn () -> Block.verifyBlock(block, block.block_header, block_hash, [:block]) end)
#   end
#
#   @doc """
#   Tests a failed verification of the merkle root in a block. In the verification, the merkle root is once again
#   calculated to be compared with the merkle root stored in the block.
#   """
#   test "Fail block verification on merkle root hash", %{tx_test: tx_test, prev_hash: prev_hash, nonce: nonce} do
#     tree = MerkleTree.makeMerkle(tx_test)
#     block = Block.createBlock(tx_test, tree.root.hash_value <> "0", prev_hash, nonce)
#     block_hash = Block.generate_block_hash(block.block_header)
#     assert_raise(Block.MerkleRootError, fn () -> Block.verifyBlock(block, block.block_header, block_hash, [:merkle]) end)
#   end
#
# end
