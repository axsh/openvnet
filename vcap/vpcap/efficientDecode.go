package vpcap

import (
	"encoding/json"
	"fmt"

	"github.com/axsh/openvnet/vcap/utils"
	"github.com/google/gopacket"
	"github.com/google/gopacket/layers"
)

func (vp *Vpacket) efficientDecode(packet gopacket.Packet, j *[]byte) error {
	// TODO: Continue adding layers and change the "fmt.Println" tests to
	// conditional struct setting for returning api calls
	// layers to consider adding:

	// higher priority

	/* ICMPv4
	   TypeCode ICMPv4TypeCode
	   Checksum uint16
	   Id       uint16
	   Seq      uint16 */

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

	/* LinkLayerDiscovery
	   ChassisID LLDPChassisID
	   PortID    LLDPPortID
	   TTL       uint16
	   Values    []LinkLayerDiscoveryValue */

	/* LinkLayerDiscoveryInfo
	   PortDescription string
	   SysName         string
	   SysDescription  string
	   SysCapabilities LLDPSysCapabilities
	   MgmtAddress     LLDPMgmtAddress
	   OrgTLVs         []LLDPOrgSpecificTLV      // Private TLVs
	   Unknown         []LinkLayerDiscoveryValue // undecoded TLVs */

	// lower priority
	// Loopback
	// GRE
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
		arp     layers.ARP
		eth     layers.Ethernet
		ip4     layers.IPv4
		ip6     layers.IPv6
		tcp     layers.TCP
		udp     layers.UDP
		dns     layers.DNS
		payload gopacket.Payload
	)
	parser := gopacket.NewDecodingLayerParser(layers.LayerTypeEthernet,
		&eth, &arp, &ip4, &ip6, &tcp, &udp, &dns, &payload)

	decodedLayers := make([]gopacket.LayerType, 0, 10)
	if err := parser.DecodeLayers(packet.Data(), &decodedLayers); err != nil {
		fmt.Println(decodedLayers)
		return err
	}
	for _, typ := range decodedLayers {
		// fmt.Println("Successfully decoded layer type:", typ)
		// fmt.Println("type:", reflect.TypeOf(typ))
		switch typ {
		case layers.LayerTypeARP:
			// fmt.Println("ARP:")
			// fmt.Println("AddrType", arp.AddrType)                   // LinkType
			// fmt.Println("Protocol", arp.Protocol)                   // EthernetType
			// fmt.Println("HwAddressSize", arp.HwAddressSize)         // uint8
			// fmt.Println("ProtAddressSize", arp.ProtAddressSize)     // uint8
			// fmt.Println("Operation", arp.Operation)                 // uint16
			// fmt.Println("SourceHwAddress", arp.SourceHwAddress)     // []byte
			// fmt.Println("SourceProtAddress", arp.SourceProtAddress) // []byte
			// fmt.Println("DstHwAddress", arp.DstHwAddress)           // []byte
			// fmt.Println("DstProtAddress", arp.DstProtAddress)       // []byte

		case layers.LayerTypeEthernet:
			// eth.Payload = nil
			var err error
			// Either send Contents, or send the other fields -- not both as they contain the same data
			if vp.DecodeProtocolData {
				*j, err = json.Marshal(struct {
					*layers.Ethernet
					Contents bool `json:"Contents,omitempty"`
					Payload  bool `json:"Payload,omitempty"`
				}{
					Ethernet: &eth,
				})
			} else {
				*j, err = json.Marshal(eth.Contents)
			}
			utils.ReturnErr(err)
			// fmt.Println(string(*j))

		// 	// fmt.Println("Eth", eth.SrcMAC, eth.DstMAC)
		// 	// if eth.EthernetType == layers.EthernetTypeLLC {
		// 	// 	fmt.Println("type:", eth.EthernetType, "length:", eth.Length)
		// 	// }

		case layers.LayerTypeIPv4:
			// fmt.Println("Version", ip4.Version)
			// fmt.Println("IHL", ip4.IHL)
			// fmt.Println("TOS", ip4.TOS)
			// fmt.Println("Length", ip4.Length)
			// fmt.Println("Id", ip4.Id)
			// if ip4.Flags > 0 {
			// 	fmt.Println("Flags:", ip4.Flags)
			// 	// if ip4.Flags&layers.IPv4EvilBit == layers.IPv4EvilBit {
			// 	// 	fmt.Println("\tthis packet has been marked unsafe! -- the evil bit is set (see http://tools.ietf.org/html/rfc3514)") //
			// 	// }
			// 	// if ip4.Flags&layers.IPv4DontFragment == layers.IPv4DontFragment {
			// 	// 	fmt.Println("\tthe 'don't fragment' flag is set")
			// 	// }
			// 	// if ip4.Flags&layers.IPv4MoreFragments == layers.IPv4MoreFragments {
			// 	// 	fmt.Println("\tthe 'more fragments' flag is set")
			// 	// }
			// }
			// fmt.Println("FragOffset", ip4.FragOffset)
			// fmt.Println("TTL", ip4.TTL)
			// fmt.Println("Protocol", ip4.Protocol)
			// fmt.Println("Checksum", ip4.Checksum)
			// fmt.Println("SrcIP", ip4.SrcIP)
			// fmt.Println("DstIP", ip4.DstIP)
			// fmt.Println("Options", ip4.Options)
			// // fmt.Println("Options string", ip4.Options.String())
			// // fmt.Println("Options type", ip4.Options.OptionType)
			// // fmt.Println("Options length", ip4.Options.OptionLength)
			// // fmt.Println("Options data", ip4.Options.OptionData)
			// fmt.Println("Padding", ip4.Padding)

		case layers.LayerTypeIPv6:
			// fmt.Println("IP6 ", ip6.SrcIP, ip6.DstIP)
			// fmt.Println("Version", ip6.Version)           // uint8
			// fmt.Println("TrafficClass", ip6.TrafficClass) // uint8
			// fmt.Println("FlowLabel", ip6.FlowLabel)       // uint32
			// fmt.Println("Length", ip6.Length)             // uint16
			// fmt.Println("NextHeader", ip6.NextHeader)     // IPProtocol
			// fmt.Println("HopLimit", ip6.HopLimit)         // uint8
			// fmt.Println("SrcIP", ip6.SrcIP)               // net.IP
			// fmt.Println("DstIP", ip6.DstIP)               // net.IP
			// fmt.Println("HopByHop", ip6.HopByHop)         // *IPv6HopByHop

		case layers.LayerTypeTCP:
		// 	fmt.Println("SrcPort:", tcp.SrcPort,
		// 		"src.layertype:", tcp.SrcPort.LayerType()) // TCPPort
		// 	fmt.Println("DstPort:", tcp.DstPort,
		// 		"dst.layertype:", tcp.DstPort.LayerType()) // TCPPort
		// 	fmt.Println("Seq", tcp.Seq)               // uint32
		// 	fmt.Println("Ack", tcp.Ack)               // uint32
		// 	fmt.Println("DataOffset", tcp.DataOffset) // uint8
		// 	fmt.Println("FIN", tcp.FIN)               // bool
		// 	fmt.Println("SYN", tcp.SYN)               // bool
		// 	fmt.Println("RST", tcp.RST)               // bool
		// 	fmt.Println("PSH", tcp.PSH)               // bool
		// 	fmt.Println("ACK", tcp.ACK)               // bool
		// 	fmt.Println("URG", tcp.URG)               // bool
		// 	fmt.Println("ECE", tcp.ECE)               // bool
		// 	fmt.Println("CWR", tcp.CWR)               // bool
		// 	fmt.Println("NS", tcp.NS)                 // bool
		// 	fmt.Println("Window", tcp.Window)         // uint16
		// 	fmt.Println("Checksum", tcp.Checksum)     // uint16
		// 	fmt.Println("Urgent", tcp.Urgent)         // uint16
		// 	fmt.Println("Options ", tcp.Options)      // []TCPOption
		// 	// fmt.Println("Options string", ip4.Options.String())
		// 	// fmt.Println("Options type", ip4.Options.OptionType)
		// 	// fmt.Println("Options type", ip4.Options.OptionType.String())
		// 	// fmt.Println("Options length", ip4.Options.OptionLength)
		// 	// fmt.Println("Options data", ip4.Options.OptionData)
		// 	fmt.Println("Padding ", tcp.Padding) // []byte

		case layers.LayerTypeUDP:
			// fmt.Println("UDP", udp.SrcPort, udp.DstPort, udp.Length, udp.Checksum)

		case layers.LayerTypeDNS:
			// fmt.Println("DNS:")
			// fmt.Println("Header fields")
			// fmt.Println("ID", dns.ID)         // uint16
			// fmt.Println("QR", dns.QR)         // bool
			// fmt.Println("OpCode", dns.OpCode) // DNSOpCode

			// fmt.Println("Authoritative answer (AA):", dns.AA)  // bool
			// fmt.Println("Truncated (TC):", dns.TC)             // bool
			// fmt.Println("Recursion desired (RD):", dns.RD)     // bool
			// fmt.Println("Recursion available (RA):", dns.RA)   // bool
			// fmt.Println("Reserved for future use (Z):", dns.Z) // uint8

			// fmt.Println("ResponseCode DNSResponseCode")
			// fmt.Println("QDCount", dns.QDCount) // uint16 // Number of questions to expect
			// fmt.Println("ANCount", dns.ANCount) // uint16 // Number of answers to expect
			// fmt.Println("NSCount", dns.NSCount) // uint16 // Number of authorities to expect
			// fmt.Println("ARCount", dns.ARCount) // uint16 // Number of additional records to expect

			// fmt.Println("Entries")
			// fmt.Println("Questions", dns.Questions)     // []DNSQuestion
			// fmt.Println("Answers", dns.Answers)         // []DNSResourceRecord
			// fmt.Println("Authorities", dns.Authorities) // []DNSResourceRecord
			// fmt.Println("Additionals", dns.Additionals) // []DNSResourceRecord

		case gopacket.LayerTypePayload:
			// fmt.Println("payload", payload.GoString())
			// fmt.Println("payload", payload, payload.Payload())
			// fmt.Println("payload", payload, ":\n", hex.Dump(payload))

		default:

		}
		// fmt.Println()
	}
	// fmt.Println()
	// fmt.Println()
	if parser.Truncated {
		fmt.Println("Packet has been truncated")
	}
	return nil
}
