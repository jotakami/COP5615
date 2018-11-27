defmodule Transaction do
  import Crypto
  
  @tx_version 1
  
  defmodule Witness do
    defstruct pubkey: <<>>, sig: <<>>
    
    @type t :: %Witness{
      pubkey: KeyAddress.Pubkey.t,
      sig:    binary
    }
    
    def sign(pubkey, privkey, sighash) do
      %Witness{
        pubkey: KeyAddress.compress_pubkey(pubkey),
        sig: :crypto.sign(:ecdsa, :sha256, sighash, [privkey, :secp256k1])
      }
    end
    
    def verify(%Witness{pubkey: pubkey, sig: sig}, msg) do
      :crypto.verify(:ecdsa, :sha256, msg, sig, [KeyAddress.uncompress_pubkey(pubkey), :secp256k1])
    end
    
    def serialize(%Witness{pubkey: pubkey, sig: sig}), do: pubkey <> sig
    
    def deserialize(<<pubkey::binary-33, sig::binary>>), do: %Witness{pubkey: pubkey, sig: sig}
    def deserialize(<<>>), do: %Witness{}
  end
  
  defmodule Vin do
    defstruct txid: <<>>, vout: 0, witness: %Witness{}
    
    @type t :: %Vin{
      txid:    <<_::256>>,
      vout:    byte,
      witness: Witness.t
    }
    
    def verify([%Vin{witness: witness} | tail], msg), do: Vin.verify(witness, msg) && verify(tail, msg)
    def verify(%Vin{witness: witness}, msg), do: Witness.verify(witness, msg)
    def verify([], _msg), do: true
    
    def serialize(vin, sighash \\ false)
    def serialize([vin | tail], sighash), do: serialize(vin, sighash) <> serialize(tail, sighash)
    def serialize(%Vin{txid: txid, vout: vout, witness: witness}, sighash) do
      txid
        <> <<vout::8>>
        <> (if sighash, do: <<>>, else: Witness.serialize(witness))
    end
    def serialize([], _sighash), do: <<>>
    
    def deserialize(<<txid::binary-32, vout::8, witness::binary>>) do
      %Vin{
        txid:    txid,
        vout:    vout,
        witness: Witness.deserialize(witness)
      }
    end
  end

  defmodule Vout do
    defstruct value: 0, pkh: <<>>
    
    @type t :: %Vout{
      value: non_neg_integer,
      pkh:   <<_::160>>
    }
    
    def serialize([vout | tail]), do: serialize(vout) <> serialize(tail)
    def serialize(%Vout{value: value, pkh: pkh}), do: <<value::32>> <> pkh
    def serialize([]), do: <<>>
    
    def deserialize(<<value::32, pkh::binary-20>>), do: %Vout{value: value, pkh: pkh}
  end
  
  defstruct version: @tx_version, vin: [], vout: []
  
  @type t :: %Transaction{
    version: non_neg_integer,
    vin:     [Vin.t, ...],
    vout:    [Vout.t, ...]
  }
  
  def verify(%Transaction{vin: vins} = tx), do: Vin.verify(vins, sighash(tx))
  
  def serialize(%Transaction{version: version, vin: vin, vout: vout}, sighash \\ false) do
    <<version::8>>
      <> <<length(vin)::8>>
      <> Vin.serialize(vin, sighash)
      <> <<length(vout)::8>>
      <> Vout.serialize(vout)
  end
  
  def deserialize(<<version::8, data::binary>>), do: deserialize(data, nil, nil, %Transaction{version: version})
  defp deserialize(<<vins::8, data::binary>>, nil, nil, tx), do: deserialize(data, vins, nil, tx)
  defp deserialize(<<vouts::8, data::binary>>, 0, nil, tx), do: deserialize(data, 0, vouts, tx)
  defp deserialize(<<>>, 0, 0, tx), do: tx
  defp deserialize(data, vins, nil, tx) do
    <<_::536, bytes::8, _::binary>> = data
    bytes = bytes + 68
    <<vin::binary-size(bytes), data::binary>> = data
    deserialize(data, vins-1, nil, Map.update!(tx, :vin, &(&1 ++ [Vin.deserialize(vin)])))
  end
  defp deserialize(<<vout::binary-24, data::binary>>, 0, vouts, tx), do: deserialize(data, 0, vouts-1, Map.update!(tx, :vout, &(&1 ++ [Vout.deserialize(vout)])))
  
  def sighash(tx), do: serialize(tx, true) |> sha256 |> sha256
  
  def sign(tx, pubkeys, privkeys) do
    sighash = sighash(tx)
    Map.update!(tx, :vin, fn vin ->
      Enum.zip(vin, Enum.zip(pubkeys, privkeys))
      |> Enum.map(fn {vin, {pubkey, privkey}} -> 
           Map.put(vin, :witness, Witness.sign(pubkey, privkey, sighash))
         end)
    end)
  end
end