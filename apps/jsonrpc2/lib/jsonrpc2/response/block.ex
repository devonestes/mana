defmodule JSONRPC2.Response.Block do
  alias Blockchain.Transaction
  alias ExthCrypto.Hash.Keccak

  import JSONRPC2.Response.Helpers

  @derive Jason.Encoder
  defstruct [
    :number,
    :hash,
    :parentHash,
    :nonce,
    :sha3Uncles,
    :logsBloom,
    :transactionsRoot,
    :stateRoot,
    :receiptsRoot,
    :miner,
    :difficulty,
    :totalDifficulty,
    :extraData,
    :size,
    :gasLimit,
    :gasUsed,
    :timestamp,
    :transactions,
    :uncles
  ]

  def new(internal_block) do
    %__MODULE__{
      number: internal_block.header.number,
      hash: encode_hex(internal_block.block_hash),
      parentHash: encode_hex(internal_block.header.parent_hash),
      nonce: encode_hex(internal_block.header.nonce),
      sha3Uncles: encode_hex(internal_block.header.sha3_uncles),
      logsBloom: encode_hex(internal_block.header.logs_bloom),
      transactionsRoot: encode_hex(internal_block.header.transactions_root),
      stateRoot: encode_hex(internal_block.header.state_root),
      receiptsRoot: encode_hex(internal_block.header.receipts_root),
      miner: encode_hex(internal_block.header.beneficiary),
      difficulty: internal_block.header.difficulty,
      totalDifficulty: internal_block.header.total_difficulty,
      extraData: internal_block.header.extra_data,
      size: internal_block.header.size,
      gasLimit: internal_block.header.gas_limit,
      gasUsed: internal_block.header.gas_used,
      timestamp: internal_block.header.timestamp,
      transactions: transaction_hashes(internal_block.transactions),
      uncles: []
    }
  end

  @spec transaction_hashes([Transaction.t()]) :: [binary()]
  defp transaction_hashes(transactions) do
    Enum.map(transactions, fn transaction ->
      transaction
      |> Transaction.serialize()
      |> ExRLP.encode()
      |> Keccak.kec()
      |> encode_hex()
    end)
  end
end