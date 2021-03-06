defmodule JSONRPC2.Bridge.Sync do
  alias Blockchain.Account
  alias Blockchain.Block
  alias Blockchain.Blocktree
  alias ExWire.PeerSupervisor
  alias ExWire.Sync
  alias JSONRPC2.Response.Block, as: ResponseBlock
  alias JSONRPC2.Response.Receipt, as: ResponseReceipt
  alias JSONRPC2.Response.Transaction, as: ResponseTransaction
  alias MerklePatriciaTree.TrieStorage

  @behaviour JSONRPC2.Client

  import JSONRPC2.Response.Helpers

  @impl true
  def connected_peer_count, do: PeerSupervisor.connected_peer_count()

  @impl true
  def last_sync_block_stats() do
    case Process.whereis(Sync) do
      nil ->
        false

      _ ->
        state = last_sync_state()

        {:ok, {block, _caching_trie}} =
          Blocktree.get_best_block(state.block_tree, state.chain, state.trie)

        {block.header.number, state.starting_block_number, state.highest_block_number}
    end
  end

  @impl true
  def block(hash_or_number, include_full_transactions) do
    state_trie = last_sync_state().trie

    case Block.get_block(hash_or_number, state_trie) do
      {:ok, block} -> ResponseBlock.new(block, include_full_transactions)
      _ -> nil
    end
  end

  @impl true
  def transaction_by_block_and_index(block_number, trx_index) do
    trie = last_sync_state().trie

    with {:ok, block} <- Block.get_block(block_number, trie) do
      case Enum.at(block.transactions, trx_index) do
        nil -> nil
        transaction -> ResponseTransaction.new(transaction, block)
      end
    else
      _ -> nil
    end
  end

  @impl true
  def transaction_by_hash(transaction_hash) do
    state_trie = last_sync_state().trie

    case Block.get_transaction_by_hash(transaction_hash, state_trie, true) do
      {transaction, block} -> ResponseTransaction.new(transaction, block)
      nil -> nil
    end
  end

  @impl true
  def block_transaction_count(number_or_hash) do
    state_trie = last_sync_state().trie

    case Block.get_block(number_or_hash, state_trie) do
      {:ok, block} ->
        block.transactions
        |> Enum.count()
        |> encode_quantity()

      _ ->
        nil
    end
  end

  @impl true
  def uncle_count(number_or_hash) do
    state_trie = last_sync_state().trie

    case Block.get_block(number_or_hash, state_trie) do
      {:ok, block} ->
        block.ommers
        |> Enum.count()
        |> encode_quantity()

      _ ->
        nil
    end
  end

  @impl true
  def starting_block_number do
    state = last_sync_state()

    Map.get(state, :starting_block_number, 0)
  end

  @impl true
  def highest_block_number do
    state = last_sync_state()

    Map.get(state, :highest_block_number, 0)
  end

  @impl true
  def code(address, block_number) do
    state_trie = last_sync_state().trie

    case Block.get_block(block_number, state_trie) do
      {:ok, block} ->
        block_state = TrieStorage.set_root_hash(state_trie, block.header.state_root)

        case Account.machine_code(block_state, address) do
          {:ok, code} -> encode_unformatted_data(code)
          _ -> nil
        end

      _ ->
        nil
    end
  end

  @impl true
  def transaction_receipt(transaction_hash) do
    state_trie = last_sync_state().trie

    case Block.get_receipt_by_transaction_hash(transaction_hash, state_trie) do
      {receipt, transaction, block} -> ResponseReceipt.new(receipt, transaction, block)
      nil -> nil
    end
  end

  @impl true
  def balance(address, block_number) do
    state_trie = last_sync_state().trie

    case Block.get_block(block_number, state_trie) do
      {:ok, block} ->
        block_state = TrieStorage.set_root_hash(state_trie, block.header.state_root)

        case Account.get_account(block_state, address) do
          nil ->
            nil

          account ->
            encode_quantity(account.balance)
        end

      _ ->
        nil
    end
  end

  @impl true
  def uncle(block_hash_or_number, index) do
    trie = last_sync_state().trie

    case Block.get_block(block_hash_or_number, trie) do
      {:ok, block} ->
        case Enum.at(block.ommers, index) do
          nil ->
            nil

          ommer_header ->
            uncle_block = %Block{header: ommer_header, transactions: [], ommers: []}

            uncle_block
            |> Block.add_metadata(trie)
            |> ResponseBlock.new()
        end

      _ ->
        nil
    end
  end

  @impl true
  def storage(storage_address, storage_key, block_number) do
    trie = last_sync_state().trie

    case Block.get_block(block_number, trie) do
      {:ok, block} ->
        block_state = TrieStorage.set_root_hash(trie, block.header.state_root)

        case Account.get_storage(block_state, storage_address, storage_key) do
          {:ok, value} ->
            value
            |> :binary.encode_unsigned()
            |> encode_unformatted_data

          _ ->
            nil
        end
    end
  end

  @impl true
  def transaction_count(address, block_number) do
    trie = last_sync_state().trie

    case Block.get_block(block_number, trie) do
      {:ok, block} ->
        block_state = TrieStorage.set_root_hash(trie, block.header.state_root)

        case Account.get_account(block_state, address) do
          nil ->
            nil

          account ->
            encode_quantity(account.nonce)
        end

      _ ->
        nil
    end
  end

  @impl true
  def last_sync_state(), do: Sync.get_state()
end
