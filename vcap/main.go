package main

import (
	"flag"
	"fmt"
	"net"
	"os"
	"reflect"
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
	handle *pcap.Handle
	err    error

	//tmp
	packetLimit  = 100
	deviceToRead = flag.String("device", "en3", "Use -device <device name> to set the device to be read for testing purposes. Default is 'en3'")
	filter       = flag.String("filter", "not tcp and not udp", "set a berkley packet filter using standard bpf syntax. Default is 'not tcp and not udp'") // tcp and port 80
	filename     = "test"

	// custom max packet size in bytes (packet will be truncated if larger than this)
	// use the constants for non-custom sizes
	snapshotLen int32         = 1538
	promiscuous               = false
	timeout     time.Duration = 30 * time.Second
	options     gopacket.SerializeOptions

	file, writeToFile, dataWanted bool = false, false, false
	// file, writeToFile, dataWanted bool = true, true, true
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

func printPacketInfo(packet gopacket.Packet) {
	fmt.Println("Layers:", packet.Layers())
	for _, layer := range packet.Layers() {
		lType := layer.LayerType()
		fmt.Println("layer type:", lType)
		fmt.Println("lType string:", lType.String())
		fmt.Println("dump", layer)
		fmt.Println()
	}

	// TODO: put this in a function or method that works for all layertypes.
	var linkFlow gopacket.Flow
	linkLayer := packet.LinkLayer()
	if linkLayer != nil {
		linkFlow = linkLayer.LinkFlow()
		lType := linkLayer.LayerType()
		fmt.Println("link layer type:", lType)
		fmt.Println("link contents:", linkLayer.LayerContents()) // header, metadata, etc.
		fmt.Println("link payload:", linkLayer.LayerPayload())
		fmt.Println("link flow (src->dst):", linkFlow)
		// fmt.Println(linkFlow.Endpoints()) // .Src(), .Dst()
		// fmt.Println(linkFlow.Src())
		// fmt.Println(linkFlow.Dst())
		// fmt.Println(linkFlow.FastHash()) // use this to compare flows if required -- the src->dst hash is guaranteed to match the dst->src hash
		fmt.Println("endpoint type:", linkFlow.EndpointType())
		fmt.Println("link layer dump:", linkLayer)
	}

	fmt.Println()
	fmt.Println("network layer:", packet.NetworkLayer())
	if packet.NetworkLayer() != nil {
		fmt.Println("network flow:", packet.NetworkLayer().NetworkFlow())
	}

	fmt.Println()
	fmt.Println("transport layer:", packet.TransportLayer())
	if packet.TransportLayer() != nil {
		fmt.Println("transport flow:", packet.TransportLayer().TransportFlow())
	}

	fmt.Println()
	fmt.Println("application layer:", packet.ApplicationLayer())
	if packet.ApplicationLayer() != nil {
		fmt.Println("application layer:", packet.ApplicationLayer().Payload())
	}

	// fmt.Println("application layer:", reflect.TypeOf(packet.ApplicationLayer()))
	// fmt.Println()
	// fmt.Println("error layer:", packet.ErrorLayer())
	// fmt.Println()
	// fmt.Println("string:", packet.String())
	// fmt.Println()
	// fmt.Println("dump:", packet.Dump())
	// fmt.Println()
	// fmt.Println("data:", packet.Data())
	fmt.Println()
	fmt.Println("metadata:", packet.Metadata())
	fmt.Println()
	fmt.Println()
	fmt.Println()
	fmt.Println()

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

func efficientPacketDecode(packet gopacket.Packet) error {
	// TODO: Continue adding layers and change the "fmt.Println" tests to struct setting for returning api calls
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

	var arp layers.ARP
	var eth layers.Ethernet
	var ip4 layers.IPv4
	var ip6 layers.IPv6
	var tcp layers.TCP
	var udp layers.UDP
	var dns layers.DNS
	var payload gopacket.Payload
	parser := gopacket.NewDecodingLayerParser(layers.LayerTypeEthernet, &eth, &arp, &ip4, &ip6, &tcp, &udp, &dns, &payload)
	decodedLayers := make([]gopacket.LayerType, 0, 10)
	if err := parser.DecodeLayers(packet.Data(), &decodedLayers); err != nil {
		return err
	}
	for _, typ := range decodedLayers {
		fmt.Println("Successfully decoded layer type:", typ)
		fmt.Println("type:", reflect.TypeOf(typ))
		switch typ {
		case layers.LayerTypeARP:
			fmt.Println("ARP:")
			fmt.Println("AddrType", arp.AddrType)                   // LinkType
			fmt.Println("Protocol", arp.Protocol)                   // EthernetType
			fmt.Println("HwAddressSize", arp.HwAddressSize)         // uint8
			fmt.Println("ProtAddressSize", arp.ProtAddressSize)     // uint8
			fmt.Println("Operation", arp.Operation)                 // uint16
			fmt.Println("SourceHwAddress", arp.SourceHwAddress)     // []byte
			fmt.Println("SourceProtAddress", arp.SourceProtAddress) // []byte
			fmt.Println("DstHwAddress", arp.DstHwAddress)           // []byte
			fmt.Println("DstProtAddress", arp.DstProtAddress)       // []byte

		case layers.LayerTypeEthernet:
			fmt.Println("Eth", eth.SrcMAC, eth.DstMAC)
			if eth.EthernetType == layers.EthernetTypeLLC {
				fmt.Println("type:", eth.EthernetType, "length:", eth.Length)
			}

		case layers.LayerTypeIPv4:
			fmt.Println("Version", ip4.Version)
			fmt.Println("IHL", ip4.IHL)
			fmt.Println("TOS", ip4.TOS)
			fmt.Println("Length", ip4.Length)
			fmt.Println("Id", ip4.Id)
			if ip4.Flags > 0 {
				fmt.Println("Flags:", ip4.Flags)
				// if ip4.Flags&layers.IPv4EvilBit == layers.IPv4EvilBit {
				// 	fmt.Println("\tthis packet has been marked unsafe! -- the evil bit is set (see http://tools.ietf.org/html/rfc3514)") //
				// }
				// if ip4.Flags&layers.IPv4DontFragment == layers.IPv4DontFragment {
				// 	fmt.Println("\tthe 'don't fragment' flag is set")
				// }
				// if ip4.Flags&layers.IPv4MoreFragments == layers.IPv4MoreFragments {
				// 	fmt.Println("\tthe 'more fragments' flag is set")
				// }
			}
			fmt.Println("FragOffset", ip4.FragOffset)
			fmt.Println("TTL", ip4.TTL)
			fmt.Println("Protocol", ip4.Protocol)
			fmt.Println("Checksum", ip4.Checksum)
			fmt.Println("SrcIP", ip4.SrcIP)
			fmt.Println("DstIP", ip4.DstIP)
			fmt.Println("Options", ip4.Options)
			// fmt.Println("Options string", ip4.Options.String())
			// fmt.Println("Options type", ip4.Options.OptionType)
			// fmt.Println("Options length", ip4.Options.OptionLength)
			// fmt.Println("Options data", ip4.Options.OptionData)
			fmt.Println("Padding", ip4.Padding)

		case layers.LayerTypeIPv6:
			fmt.Println("IP6 ", ip6.SrcIP, ip6.DstIP)
			fmt.Println("Version", ip6.Version)           // uint8
			fmt.Println("TrafficClass", ip6.TrafficClass) // uint8
			fmt.Println("FlowLabel", ip6.FlowLabel)       // uint32
			fmt.Println("Length", ip6.Length)             // uint16
			fmt.Println("NextHeader", ip6.NextHeader)     // IPProtocol
			fmt.Println("HopLimit", ip6.HopLimit)         // uint8
			fmt.Println("SrcIP", ip6.SrcIP)               // net.IP
			fmt.Println("DstIP", ip6.DstIP)               // net.IP
			fmt.Println("HopByHop", ip6.HopByHop)         // *IPv6HopByHop

		case layers.LayerTypeTCP:
			fmt.Println("SrcPort:", tcp.SrcPort,
				"src.layertype:", tcp.SrcPort.LayerType()) // TCPPort
			fmt.Println("DstPort:", tcp.DstPort,
				"dst.layertype:", tcp.DstPort.LayerType()) // TCPPort
			fmt.Println("Seq", tcp.Seq)               // uint32
			fmt.Println("Ack", tcp.Ack)               // uint32
			fmt.Println("DataOffset", tcp.DataOffset) // uint8
			fmt.Println("FIN", tcp.FIN)               // bool
			fmt.Println("SYN", tcp.SYN)               // bool
			fmt.Println("RST", tcp.RST)               // bool
			fmt.Println("PSH", tcp.PSH)               // bool
			fmt.Println("ACK", tcp.ACK)               // bool
			fmt.Println("URG", tcp.URG)               // bool
			fmt.Println("ECE", tcp.ECE)               // bool
			fmt.Println("CWR", tcp.CWR)               // bool
			fmt.Println("NS", tcp.NS)                 // bool
			fmt.Println("Window", tcp.Window)         // uint16
			fmt.Println("Checksum", tcp.Checksum)     // uint16
			fmt.Println("Urgent", tcp.Urgent)         // uint16
			fmt.Println("Options ", tcp.Options)      // []TCPOption
			// fmt.Println("Options string", ip4.Options.String())
			// fmt.Println("Options type", ip4.Options.OptionType)
			// fmt.Println("Options type", ip4.Options.OptionType.String())
			// fmt.Println("Options length", ip4.Options.OptionLength)
			// fmt.Println("Options data", ip4.Options.OptionData)
			fmt.Println("Padding ", tcp.Padding) // []byte

		case layers.LayerTypeUDP:
			fmt.Println("UDP", udp.SrcPort, udp.DstPort, udp.Length, udp.Checksum)

		case layers.LayerTypeDNS:
			fmt.Println("DNS:")
			fmt.Println("Header fields")
			fmt.Println("ID", dns.ID)         // uint16
			fmt.Println("QR", dns.QR)         // bool
			fmt.Println("OpCode", dns.OpCode) // DNSOpCode

			fmt.Println("Authoritative answer (AA):", dns.AA)  // bool
			fmt.Println("Truncated (TC):", dns.TC)             // bool
			fmt.Println("Recursion desired (RD):", dns.RD)     // bool
			fmt.Println("Recursion available (RA):", dns.RA)   // bool
			fmt.Println("Reserved for future use (Z):", dns.Z) // uint8

			fmt.Println("ResponseCode DNSResponseCode")
			fmt.Println("QDCount", dns.QDCount) // uint16 // Number of questions to expect
			fmt.Println("ANCount", dns.ANCount) // uint16 // Number of answers to expect
			fmt.Println("NSCount", dns.NSCount) // uint16 // Number of authorities to expect
			fmt.Println("ARCount", dns.ARCount) // uint16 // Number of additional records to expect

			fmt.Println("Entries")
			fmt.Println("Questions", dns.Questions)     // []DNSQuestion
			fmt.Println("Answers", dns.Answers)         // []DNSResourceRecord
			fmt.Println("Authorities", dns.Authorities) // []DNSResourceRecord
			fmt.Println("Additionals", dns.Additionals) // []DNSResourceRecord

		case gopacket.LayerTypePayload:
			// fmt.Println("payload", payload.GoString())
			fmt.Println("payload", payload, payload.Payload())

			// case gopacket.UnsupportedLayerType:
			// 	fmt.Println("there is no decoder for this type in the current parser")

		}
		fmt.Println()
	}
	fmt.Println()
	fmt.Println()
	// if decodedLayers.Truncated {
	if parser.Truncated {
		fmt.Println("  Packet has been truncated")
	}
	return err
}

func main() {
	if file {
		handle, err = pcap.OpenOffline(Join("", filename))
	} else { // from device
		handle, err = pcap.OpenLive(*deviceToRead, snapshotLen, promiscuous, timeout)
	}
	throwErr(err)

	if *filter != "" {
		// subnet can be dotted quad, triple, double, or single -- the netmask will
		// be set accordingly (i.e. a quad gets a mask of 255.255.255.255, a triple
		// gets 255.255.255.0, a double is 255.255.0.0, and single 255.0.0.0)
		// *filter = "net 192.168"

		// the mask can be specified more specifically with e.g.:
		// *filter = "net 192.168 mask 63.87.0.0"

		// src and dst can be set independently like so:
		*filter = "src net 192.168 and dst net 192"

		throwErr(handle.SetBPFFilter(*filter))
	}

	// var f *os.File
	var w *pcapgo.Writer
	packetCount := 0
	if writeToFile { // TODO: fix scopes
		f, err := os.Create(Join("", filename)) // TODO: think about streaming this to the browser if requested
		throwErr(err)
		w := pcapgo.NewWriter(f)
		w.WriteFileHeader(uint32(snapshotLen), layers.LinkTypeEthernet)
		defer f.Close()
	}

	find()

	packetSource := gopacket.NewPacketSource(handle, handle.LinkType())
	for packet := range packetSource.Packets() {
		if writeToFile {
			w.WritePacket(packet.Metadata().CaptureInfo, packet.Data())

			// Only capture to limit and then stop
			packetCount++
			if packetCount > packetLimit {
				break
			}
			if dataWanted {
				// send packet.Data()
			}
		}
		if err := efficientPacketDecode(packet); err != nil {
			fmt.Println()
			fmt.Println()
			fmt.Println()
			fmt.Println()
			fmt.Println(err)
			fmt.Println()
			printPacketInfo(packet)
		}
	}
}
