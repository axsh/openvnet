package vpcap

import (
	"bytes"
	"encoding/json"
	"net"
	"reflect"

	"github.com/axsh/openvnet/vcap/utils"
	"github.com/google/gopacket"
	"github.com/google/gopacket/layers"
)

type DecodedLayer struct {
	*layers.BaseLayer
	Contents bool `json:"Contents,omitempty"`
	Payload  bool `json:"Payload,omitempty"`
	// Contents bool `json:"-"`
	// Payload  bool `json:"-"`
	// Contents bool `-`
	// Payload  bool `-`
}

type RawTcpIpPacket struct {
	Metadata  gopacket.PacketMetadata `json:"metadata,omitempty"`
	Link      []byte                  `json:"link,omitempty"`
	Network   []byte                  `json:"network,omitempty"`
	Transport []byte                  `json:"transport,omitempty"`
	Payload   []byte                  `json:"payload,omitempty"`
}

type DecodedTcpIpPacket struct {
	Metadata  gopacket.PacketMetadata `json:"metadata,omitempty"`
	Link      gopacket.Layer          `json:"link,omitempty"`
	Network   gopacket.Layer          `json:"network,omitempty"`
	Transport gopacket.Layer          `json:"transport,omitempty"`
	// Link      interface{} `json:"link,omitempty"`
	// Network   interface{} `json:"network,omitempty"`
	// Transport interface{} `json:"transport,omitempty"`
	Payload []byte `json:"payload,omitempty"`
}

func (p *DecodedTcpIpPacket) setPayload(packet gopacket.Packet) {
	if packet.ApplicationLayer() != nil {
		p.Payload = packet.ApplicationLayer().LayerContents()
	} else if packet.TransportLayer() != nil {
		p.Payload = packet.TransportLayer().LayerPayload()
	} else if packet.NetworkLayer() != nil {
		p.Payload = packet.NetworkLayer().LayerPayload()
	}
	if len(p.Payload) == 0 {
		if packet.LinkLayer() != nil {
			p.Payload = packet.LinkLayer().LayerPayload()
		} else {
			p.Payload = packet.Data()
		}
	}
}

func setZeroVal(v reflect.Value) {
	if v.IsValid() && v.CanSet() {
		v.Set(reflect.Zero(v.Type()))
	}
}

func (p *DecodedTcpIpPacket) dedupe() {
	if p.Link != nil {
		setZeroVal(reflect.ValueOf(p.Link).Elem().FieldByName("Payload"))
		setZeroVal(reflect.ValueOf(p.Link).Elem().FieldByName("Contents"))
	}
	if p.Network != nil {
		setZeroVal(reflect.ValueOf(p.Network).Elem().FieldByName("Payload"))
		setZeroVal(reflect.ValueOf(p.Network).Elem().FieldByName("Contents"))
	}
	if p.Transport != nil {
		setZeroVal(reflect.ValueOf(p.Transport).Elem().FieldByName("Payload"))
		setZeroVal(reflect.ValueOf(p.Transport).Elem().FieldByName("Contents"))
	}
}

// generalDecode decodes into 4 layers corresponding with the tcp/ip layering
// scheme (similar to OSI layers 2,3,4, and 7). Because this generalized
// solution can't preallocate memory, it is substantially slower (at least an
// order of magnitude) than the "efficientDecode" function. As such, it should
// only be used as a fallback for protocols not covered by the efficientDecode
// decoder. This decoder should work on anything with a standardized link layer,
// but for packets lacking this, the raw packet data will be returned instead.
func (vp *Vpacket) generalDecode(packet gopacket.Packet, j *[]byte) error {
	// err can't be assigned as normal without also assigning a local j
	var err error

	dpkt := DecodedTcpIpPacket{
		Link:      packet.LinkLayer(),
		Network:   packet.NetworkLayer(),
		Transport: packet.TransportLayer(),
	}
	if vp.SendMetadata {
		dpkt.Metadata = *packet.Metadata()
	}
	dpkt.setPayload(packet)
	if !vp.DecodeProtocolData {
		rpkt := RawTcpIpPacket{
			Metadata: dpkt.Metadata,
			Payload:  dpkt.Payload,
		}
		if packet.LinkLayer() != nil {
			rpkt.Link = packet.LinkLayer().LayerContents()
		}
		if packet.NetworkLayer() != nil {
			rpkt.Network = packet.NetworkLayer().LayerContents()
		}
		if packet.TransportLayer() != nil {
			rpkt.Transport = packet.TransportLayer().LayerContents()
		}
		*j, err = json.Marshal(&rpkt)
	} else {
		dpkt.dedupe()
		var b []byte
		b, err = json.Marshal(&dpkt)
		*j = bytes.Replace(b, []byte("\"Contents\":null,\"Payload\":null,"), []byte(""), 3)
	}
	return err
}

// TODO: think of something more generic and flexible than a tcp restriction
func (vp *Vpacket) createAndSendTCPpacket(rawBytes []byte) {
	// these layers should be fields in the struct
	ipLayer := &layers.IPv4{
		SrcIP: net.IP{127, 0, 0, 1},
		DstIP: net.IP{8, 8, 8, 8},
	}
	ethernetLayer := &layers.Ethernet{
		SrcMAC: net.HardwareAddr{0xFF, 0xAA, 0xFA, 0xAA, 0xFF, 0xAA},
		DstMAC: net.HardwareAddr{0xBD, 0xBD, 0xBD, 0xBD, 0xBD, 0xBD},
	}
	tcpLayer := &layers.TCP{
		SrcPort: layers.TCPPort(4321),
		DstPort: layers.TCPPort(80),
	}
	buffer := gopacket.NewSerializeBuffer()
	var options gopacket.SerializeOptions
	gopacket.SerializeLayers(buffer, options,
		ethernetLayer,
		ipLayer,
		tcpLayer,
		gopacket.Payload(rawBytes),
	)
	utils.ReturnErr(vp.handle.WritePacketData(buffer.Bytes()))

	// for packets formed elsewhere --
	// or just raw data...better hope it has an address somewhere!
	// utils.ReturnErr(handle.WritePacketData(rawBytes))
	// to make this safer, it could be checked with something like:
	// packet := gopacket.NewPacket(
	// 	rawBytes,
	// 	layers.LayerTypeEthernet,
	// 	gopacket.Default,
	// )
	// utils.ReturnErr(handle.WritePacketData(packet.Data()))
	// but that requires it to have an ethernet layer
}
