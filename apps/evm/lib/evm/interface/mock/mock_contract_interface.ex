defmodule EVM.Interface.Mock.MockContractInterface do
  @moduledoc """
  Simple implementation of a contract interface.
  """

  defstruct [
    state: nil,
    gas: nil,
    sub_state: nil,
    output: nil
  ]

  def new(state, gas, sub_state, output) do
    %__MODULE__{
      state: state,
      gas: gas,
      sub_state: sub_state,
      output: output
    }
  end

end

defimpl EVM.Interface.ContractInterface, for: EVM.Interface.Mock.MockContractInterface do

  @spec message_call(EVM.Interface.ContractInterface.t, EVM.state, EVM.address, EVM.address, EVM.address, EVM.address, EVM.Gas.t, EVM.Gas.gas_price, EVM.Wei.t, EVM.Wei.t, binary(), integer(), Header.t) :: { EVM.state, EVM.Gas.t, EVM.SubState.t, EVM.VM.output }
  def message_call(mock_contract_interface, state, sender, originator, recipient, contract, available_gas, gas_price, value, apparent_value, data, stack_depth, block_header) do
    {
      mock_contract_interface.state,
      mock_contract_interface.gas,
      mock_contract_interface.sub_state,
      mock_contract_interface.output
    }
  end

end