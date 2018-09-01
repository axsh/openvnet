package vpcap

import (
	"encoding/json"
	"errors"

	"github.com/axsh/openvnet/vcap/utils"
	"github.com/google/gopacket"
	"github.com/google/gopacket/layers"
)

type ContentLayer struct {
	Layertype string `json:"layertype,omitempty"`
	*layers.BaseLayer
	// Contents bool `json:"Contents,omitempty"`
	Payload bool `json:"Payload,omitempty"`
}

type RawSortedPacket struct {
	ID        string                   `json:"id,omitempty"`
	Interface string                   `json:"interface,omitempty"`
	PacketNum string                   `json:"number,omitempty"`
	Metadata  *gopacket.PacketMetadata `json:"metadata,omitempty"`
	Layers    []interface{}            `json:"layers,omitempty"`
	Payload   []byte                   `json:"payload,omitempty"`
}

type DecodedPacket struct {
	ID        string                   `json:"id,omitempty"`
	Interface string                   `json:"interface,omitempty"`
	PacketNum string                   `json:"number,omitempty"`
	Metadata  *gopacket.PacketMetadata `json:"metadata,omitempty"`
	Layers    []gopacket.Layer         `json:"layers,omitempty"`
	Payload   []byte                   `json:"payload,omitempty"`
}

func (vp *Vpacket) efficientDecode(packet gopacket.Packet, j *[]byte) error {
	// func (vp *Vpacket) efficientDecode(j *[]byte) error {
	// TODO: Continue adding layers and change the "fmt.Println" tests to
	// conditional struct setting for returning api calls
	// layers to consider adding:

	/* ICMPv6
	   TypeCode ICMPv6TypeCode
	   Checksum uint16
	   // TypeBytes is deprecated and always nil. See the different ICMPv6 message types
	   // instead (e.g. ICMPv6TypeRouterSolicitation).
	   // TypeBytes []byte*/

	/* ICMPv6Echo
	   Identifier uint16
	   SeqNumber  uint16 */

	/* ICMPv6NeighborSolicitation
	   TargetAddress net.IP
	   Options       ICMPv6Options */

	/* ICMPv6NeighborAdvertisement
	   Flags         uint8
	   TargetAddress net.IP
	   Options       ICMPv6Options */

	// vxlan
	// IPSec
	// dhcp
	// UDPLite
	// Router
	// dot11 (this is really big...)
	// IPProtocol
	// IGMP
	// NTP
	// OSPF
	// PPP
	// PPPoE
	// USB
	// RadioTap

	var (
		dpkt DecodedPacket
		rpkt RawSortedPacket

		loopback layers.Loopback
		icmp4    layers.ICMPv4
		arp      layers.ARP
		eth      layers.Ethernet
		gre      layers.GRE
		ip4      layers.IPv4
		ip6      layers.IPv6
		tcp      layers.TCP
		udp      layers.UDP
		dns      layers.DNS
		payload  gopacket.Payload
	)
	parser := gopacket.NewDecodingLayerParser(layers.LayerTypeEthernet,
		// parser := gopacket.NewDecodingLayerParser(vp.handle.LinkType().LayerType(),
		&eth, &loopback, &icmp4, &arp, &gre, &ip4, &ip6, &tcp, &udp, &dns, &payload)

	// TODO: find a better way to decide on the capacity of this array rather than an arbitrary 10 layer max
	decodedLayers := make([]gopacket.LayerType, 0, 10)
	if err := parser.DecodeLayers(packet.Data(), &decodedLayers); err != nil {
		// data, captureInfo, err := vp.handle.ZeroCopyReadPacketData()
		// if len(data) == 0 {
		// 	return nil
		// }
		// fmt.Println(captureInfo)
		// fmt.Println(data)
		// if err := parser.DecodeLayers(data, &decodedLayers); err != nil {
		// fmt.Println(decodedLayers)
		return err
	}
	if vp.SendMetadata {
		dpkt.Metadata = packet.Metadata()
	}
	dl := len(decodedLayers)
	if vp.DecodeProtocolData {
		dpkt.Layers = make([]gopacket.Layer, dl, dl)
		dpkt.ID = vp.ID
		dpkt.Interface = vp.IfaceToRead
		dpkt.PacketNum = vp.packetNum
	} else {
		// rpkt.Layers = make([]*ContentLayer, dl, dl)
		rpkt.Layers = make([]interface{}, dl, dl)
		rpkt.ID = vp.ID
		rpkt.Interface = vp.IfaceToRead
		rpkt.PacketNum = vp.packetNum
		rpkt.Metadata = dpkt.Metadata
	}
	for i, typ := range decodedLayers {

		// Either send Contents, or send the other fields
		// -- not both as they contain the same data
		switch typ {

		case layers.LayerTypeLoopback:
			if vp.DecodeProtocolData {
				dpkt.Layers[i] = struct {
					Layertype string `json:"layertype"`
					*layers.Loopback
					Contents bool `json:"Contents,omitempty"`
					Payload  bool `json:"Payload,omitempty"`
				}{
					Layertype: "loopback",
					Loopback:  &loopback,
				}
			} else {
				rpkt.Layers[i] = &ContentLayer{
					Layertype: "loopback",
					BaseLayer: &loopback.BaseLayer,
				}
			}

		case layers.LayerTypeICMPv4:
			if vp.DecodeProtocolData {
				dpkt.Layers[i] = struct {
					Layertype string `json:"layertype"`
					*layers.ICMPv4
					Contents bool `json:"Contents,omitempty"`
					Payload  bool `json:"Payload,omitempty"`
				}{
					Layertype: "icmp4",
					ICMPv4:    &icmp4,
				}
			} else {
				rpkt.Layers[i] = &ContentLayer{
					Layertype: "icmp4",
					BaseLayer: &icmp4.BaseLayer,
				}
			}

		case layers.LayerTypeARP:
			if vp.DecodeProtocolData {
				dpkt.Layers[i] = struct {
					Layertype string `json:"layertype"`
					*layers.ARP
					Contents bool `json:"Contents,omitempty"`
					Payload  bool `json:"Payload,omitempty"`
				}{
					Layertype: "arp",
					ARP:       &arp,
				}
			} else {
				rpkt.Layers[i] = &ContentLayer{
					Layertype: "arp",
					BaseLayer: &arp.BaseLayer,
				}
			}

		case layers.LayerTypeEthernet:
			if vp.DecodeProtocolData {
				dpkt.Layers[i] = struct {
					Layertype string `json:"layertype"`
					*layers.Ethernet
					Contents bool `json:"Contents,omitempty"`
					Payload  bool `json:"Payload,omitempty"`
				}{
					Layertype: "ethernet",
					Ethernet:  &eth,
				}
			} else {
				rpkt.Layers[i] = &ContentLayer{
					Layertype: "ethernet",
					BaseLayer: &eth.BaseLayer,
				}
			}

		case layers.LayerTypeIPv4:
			if vp.DecodeProtocolData {
				dpkt.Layers[i] = struct {
					Layertype string `json:"layertype"`
					*layers.IPv4
					Contents bool `json:"Contents,omitempty"`
					Payload  bool `json:"Payload,omitempty"`
				}{
					Layertype: "IPv4",
					IPv4:      &ip4,
				}
			} else {
				rpkt.Layers[i] = &ContentLayer{
					Layertype: "IPv4",
					BaseLayer: &ip4.BaseLayer,
				}
			}

		case layers.LayerTypeGRE:
			if vp.DecodeProtocolData {
				dpkt.Layers[i] = struct {
					Layertype string `json:"layertype"`
					*layers.GRE
					Contents bool `json:"Contents,omitempty"`
					Payload  bool `json:"Payload,omitempty"`
				}{
					Layertype: "GRE",
					GRE:       &gre,
				}
			} else {
				rpkt.Layers[i] = &ContentLayer{
					Layertype: "GRE",
					BaseLayer: &gre.BaseLayer,
				}
			}

		case layers.LayerTypeIPv6:
			if vp.DecodeProtocolData {
				dpkt.Layers[i] = struct {
					Layertype string `json:"layertype"`
					*layers.IPv6
					Contents bool `json:"Contents,omitempty"`
					Payload  bool `json:"Payload,omitempty"`
				}{
					Layertype: "IPv6",
					IPv6:      &ip6,
				}
			} else {
				rpkt.Layers[i] = &ContentLayer{
					Layertype: "IPv6",
					BaseLayer: &ip6.BaseLayer,
				}
			}

		case layers.LayerTypeTCP:
			if vp.DecodeProtocolData {
				dpkt.Layers[i] = struct {
					Layertype string `json:"layertype"`
					*layers.TCP
					Contents bool `json:"Contents,omitempty"`
					Payload  bool `json:"Payload,omitempty"`
				}{
					Layertype: "tcp",
					TCP:       &tcp,
				}
			} else {
				rpkt.Layers[i] = &ContentLayer{
					Layertype: "tcp",
					BaseLayer: &tcp.BaseLayer,
				}
			}

		case layers.LayerTypeUDP:
			if vp.DecodeProtocolData {
				dpkt.Layers[i] = struct {
					Layertype string `json:"layertype"`
					*layers.UDP
					Contents bool `json:"Contents,omitempty"`
					Payload  bool `json:"Payload,omitempty"`
				}{
					Layertype: "udp",
					UDP:       &udp,
				}
			} else {
				rpkt.Layers[i] = &ContentLayer{
					Layertype: "udp",
					BaseLayer: &udp.BaseLayer,
				}
			}

		case layers.LayerTypeDNS:
			if vp.DecodeProtocolData {
				dpkt.Layers[i] = struct {
					Layertype string `json:"layertype"`
					*layers.DNS
					Contents bool `json:"Contents,omitempty"`
					Payload  bool `json:"Payload,omitempty"`
				}{
					Layertype: "dns",
					DNS:       &dns,
				}
			} else {
				rpkt.Layers[i] = &ContentLayer{
					Layertype: "dns",
					BaseLayer: &dns.BaseLayer,
				}
			}

		case gopacket.LayerTypePayload:
			if vp.DecodeProtocolData {
				dpkt.Layers[i] = &struct {
					*gopacket.Payload `json:"payload"`
				}{Payload: &payload}
			} else {
				rpkt.Layers[i] = &struct {
					*gopacket.Payload `json:"payload"`
				}{Payload: &payload}
			}
		}
	}

	var err error
	if vp.DecodeProtocolData {
		*j, err = json.Marshal(dpkt)
	} else {
		*j, err = json.Marshal(rpkt)
	}
	vp.ws.ThrowErr(err, "marshalling error on", vp.ID, "-", vp.packetNum, ": ")

	if parser.Truncated {
		vp.ws.ThrowErr(errors.New(utils.Join("packet ", vp.ID, "-", vp.packetNum, " exceeded SnapshotLen -- it has been truncated ")))
	}
	return nil
}
