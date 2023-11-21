defmodule ExWebRTC.PeerConnection.DemuxerTest do
  use ExUnit.Case, async: true

  alias ExRTP.Packet
  alias ExRTP.Packet.Extension
  alias ExWebRTC.PeerConnection.Demuxer

  @mid "1"

  @payload_type 111
  @ssrc 333_333
  @deserialized_packet %Packet{
    payload_type: @payload_type,
    sequence_number: 5,
    timestamp: 0,
    ssrc: @ssrc,
    payload: <<>>
  }

  @packet Packet.encode(@deserialized_packet)
  @packet_mid @deserialized_packet
              |> Packet.set_extension(:two_byte, [%Extension{id: 15, data: @mid}])
              |> Packet.encode()

  @demuxer %Demuxer{extensions: %{15 => {Extension.SourceDescription, :mid}}}

  test "ssrc already mapped, without extension" do
    demuxer = %Demuxer{@demuxer | ssrc_to_mid: %{@ssrc => @mid}}

    assert {:ok, new_demuxer, @mid, _packet} = Demuxer.demux(demuxer, @packet)
    assert new_demuxer == %Demuxer{demuxer | ssrc_to_mid: %{@ssrc => @mid}}
  end

  test "ssrc already mapped, with extension with the same mid" do
    demuxer = %Demuxer{@demuxer | ssrc_to_mid: %{@ssrc => @mid}}

    assert {:ok, new_demuxer, @mid, _packet} = Demuxer.demux(demuxer, @packet_mid)
    assert new_demuxer == %Demuxer{demuxer | ssrc_to_mid: %{@ssrc => @mid}}
  end

  test "ssrc already mapped, with extension with different mid" do
    demuxer = %Demuxer{@demuxer | ssrc_to_mid: %{@ssrc => "other"}}

    assert_raise(RuntimeError, fn -> Demuxer.demux(demuxer, @packet_mid) end)
  end

  test "ssrc not mapped, with extension" do
    assert {:ok, new_demuxer, @mid, _packet} = Demuxer.demux(@demuxer, @packet_mid)
    assert new_demuxer == %Demuxer{@demuxer | ssrc_to_mid: %{@ssrc => @mid}}
  end

  test "ssrc not mapped, without extension, with unique payload type" do
    demuxer = %Demuxer{@demuxer | pt_to_mid: %{@payload_type => @mid}}

    assert {:ok, new_demuxer, @mid, _packet} = Demuxer.demux(demuxer, @packet)
    assert new_demuxer == %Demuxer{demuxer | ssrc_to_mid: %{@ssrc => @mid}}
  end

  test "unmatchable ssrc" do
    assert {:error, :no_matching_mid} = Demuxer.demux(@demuxer, @packet)
  end
end