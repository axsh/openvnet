package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"net"
	"os"
	"strings"
	"time"

	"github.com/google/gopacket"
	"github.com/google/gopacket/layers"
	"github.com/google/gopacket/pcap"
	"github.com/google/gopacket/pcapgo"
)

const (
	standardPacketMaxLen   int32 = 1538
	babyGiantPacketMaxLen  int32 = 1600
	jumboPacketMaxLen      int32 = 9038
	superJumboPacketMaxLen int32 = 65535

	// this would have to be edited in the pcap lib to
	// work with a uint32 instead of the int32 that it expects:
	// ipv6JumbogramPacketMaxLen uint32 = 4294967295
)

var (
	//tmp
	deviceToRead = flag.String("device", "en3", "Use -device <device name> to set the device to be read for testing purposes. Default is 'en3'")
	filter       = flag.String("filter", "not tcp and not udp", "set a berkley packet filter using standard bpf syntax. Default is 'not tcp and not udp'") // tcp and port 80

	// custom max packet size in bytes (packet will be truncated if larger than this)
	// use the constants for non-custom sizes
	snapshotLen int32         = 1538
	promiscuous               = false
	timeout     time.Duration = 30 * time.Second
	options     gopacket.SerializeOptions
)

// TODO: find start and stop session packets -- not sure how to do this yet...

func init() {
	flag.Parse()
}

// Join joins arbitrary strings
func Join(args ...string) string {
	return strings.Join(args, "")
}

// Join joins arbitrary strings separated by any arbitrary string
func JoinWithSep(separator string, args ...string) string {
	return strings.Join(args, separator)
}

func throwErr(err error, msg ...string) {
	if err != nil {
		// send Join(JoinWithSep(" ", msg), err.Error())
	}
}

func find() {
	// Find all devices
	devices, err := pcap.FindAllDevs()
	throwErr(err)

	// Print device information
	fmt.Println("Devices found:")
	for _, device := range devices {
		fmt.Println("\nName: ", device.Name)
		fmt.Println("Description: ", device.Description)
		fmt.Println("Devices addresses: ", device.Description)
		for _, address := range device.Addresses {
			fmt.Println("- IP address: ", address.IP)
			fmt.Println("- Subnet mask: ", address.Netmask)
		}
	}
}

// generalDecode decodes into 4 layers corresponding with the
// tcp/ip layering scheme (similar to OSI layers 2,3,4, and 7)
// Because this generalized solution must always include the payload,
// it is substantially slower than the "efficientDecode" function.
// As such, it should only be used as a fallback for protocols not
// covered by the efficientDecode decoder.
func generalDecode(packet gopacket.Packet) {
	if packet.LinkLayer() != nil {
		j, err := json.Marshal(packet.LinkLayer())
		throwErr(err)
		fmt.Println()
		fmt.Println("link layer:")
		fmt.Println(string(j))
	}
	if packet.NetworkLayer() != nil {
		j, err := json.Marshal(packet.NetworkLayer())
		throwErr(err)
		fmt.Println()
		fmt.Println("network layer:")
		fmt.Println(string(j))
	}
	if packet.TransportLayer() != nil {
		j, err := json.Marshal(packet.TransportLayer())
		throwErr(err)
		fmt.Println()
		fmt.Println("transport layer:")
		fmt.Println(string(j))
	}
	if packet.ApplicationLayer() != nil {
		j, err := json.Marshal(packet.ApplicationLayer())
		throwErr(err)
		fmt.Println()
		fmt.Println("application layer:")
		fmt.Println(string(j))
	}
	fmt.Println("metadata:", packet.Metadata())
}

// TODO: make this a method on a tcpPacket typed struct or better yet,
// think of something more generic and flexible than a tcp restriction
func createAndSendTCPpacket(handle *pcap.Handle, rawBytes []byte) {
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
	gopacket.SerializeLayers(buffer, options,
		ethernetLayer,
		ipLayer,
		tcpLayer,
		gopacket.Payload(rawBytes),
	)
	throwErr(handle.WritePacketData(buffer.Bytes()))

	// for packets formed elsewhere --
	// or just raw data...better hope it has an address somewhere!
	// throwErr(handle.WritePacketData(rawBytes))
	// to make this safer, it could be checked with something like:
	// packet := gopacket.NewPacket(
	// 	rawBytes,
	// 	layers.LayerTypeEthernet,
	// 	gopacket.Default,
	// )
	// throwErr(handle.WritePacketData(packet.Data()))
	// but that requires it to have an ethernet layer
}

func efficientDecode(packet gopacket.Packet, decodeProtocolData bool) error {
	// TODO: Continue adding layers and change the "fmt.Println" tests to conditional struct setting for returning api calls
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
			var (
				j   []byte
				err error
			)
			// Either send Contents, or send the other fields -- not both as they contain the same data
			if decodeProtocolData {
				j, err = json.Marshal(struct {
					*layers.Ethernet
					Contents bool `json:"Contents,omitempty"`
					Payload  bool `json:"Payload,omitempty"`
				}{
					Ethernet: &eth,
				})
			} else {
				j, err := json.Marshal(eth.Contents)
			}
			throwErr(err)
			fmt.Println(string(j))
			fmt.Println()

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

func main() {
	var (
		handle *pcap.Handle
		err    error

		// TODO: get all of the following from an api call (through a websocket or maybe grpc)
		packetLimit = 10000 // TODO: decide on a max for this based on hardware limits

		// as a sanity check, might as well set these to have
		// the username or something identifiable in them
		readFile  = "readTest.pcap"
		writeFile = "writeTest.pcap"

		decodeProtocolData = true

		// defaults should be as shown. If both are true return an error.
		readFromFile = false
		writeToFile  = false

		// defaults should be as shown with specified dependencies
		sendRawPacket = false // if this is true and decodePacket is not specified, decodePacket should be false by default
		decodePacket  = true  // if this is true and sendRawPacket is not specified, sendRawPacket should be false by default
	)

	find()

	if readFromFile {
		handle, err = pcap.OpenOffline(readFile)
	} else { // read from device
		handle, err = pcap.OpenLive(*deviceToRead, snapshotLen, promiscuous, timeout)
	}
	throwErr(err)

	if *filter != "" {
		// subnet can be dotted quad, triple, double, or single -- the netmask will
		// be set accordingly (i.e. a quad gets a mask of 255.255.255.255, a triple
		// gets 255.255.255.0, a double is 255.255.0.0, and single 255.0.0.0)
		// *filter = "net 192.168"

		// more specific mask with e.g.:
		// *filter = "net 192.168 mask 63.87.0.0"

		// src and dst can be set independently like so:
		// *filter = "src net 192.168 and dst net 192"

		// *filter = "icmp"
		// *filter = "ip6"
		*filter = ""

		throwErr(handle.SetBPFFilter(*filter))
	}

	var w *pcapgo.Writer
	if writeToFile {
		f, err := os.Create(Join("", writeFile))
		throwErr(err)
		defer f.Close()
		w = pcapgo.NewWriter(f)
		// w.WriteFileHeader(uint32(snapshotLen), layers.LinkTypeEthernet)
		w.WriteFileHeader(uint32(snapshotLen), handle.LinkType())
	}

	packetCount := 0
	packetSource := gopacket.NewPacketSource(handle, handle.LinkType())
	for packet := range packetSource.Packets() {
		go func() {
			if writeToFile {
				w.WritePacket(packet.Metadata().CaptureInfo, packet.Data())
			}
			if sendRawPacket {
				// send packet.Data()
			}
			if decodePacket {
				// TODO: do something more sensible than passing "decodeProtocolData" in as a variable...
				if err := efficientDecode(packet, decodeProtocolData); err != nil {
					if !strings.Contains(err.Error(), "No decoder for layer type") {
						throwErr(err)
					}
					fmt.Println()
					generalDecode(packet)
				}
			}
		}()

		// Only capture to limit and then stop
		packetCount++
		if packetCount > packetLimit {
			break
		}
	}
}
