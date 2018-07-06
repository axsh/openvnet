package main

import (
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

var (
	handle   *pcap.Handle
	err      error
	ethLayer layers.Ethernet
	ipLayer  layers.IPv4
	tcpLayer layers.TCP

	//tmp
	packetLimit  int           = 100
	deviceToRead string        = "en3"
	filename     string        = "test"
	snapshotLen  int32         = 1024
	promiscuous  bool          = false
	timeout      time.Duration = 30 * time.Second
	// buffer       gopacket.SerializeBuffer
	options gopacket.SerializeOptions

	file, filter, writeToFile, dataWanted bool = false, false, false, false //true, true, true, true
)

// TODO:
// masking filter (i.e. show all *except* for e.g. a specific ip address)
// subnet filter (i.e. show all 192.168.*.* etc.)
// find stop and start session packets -- not sure how to do this yet...

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

// // Loop through packets in file and stream them to a channel
// func readPackets(handle *pcap.Handle) <-chan gopacket.Packet {
// 	// packetChan := make(chan gopacket.Packet)
// 	packetSource := gopacket.NewPacketSource(handle, handle.LinkType())
// 	return packetSource.Packets()
// }

// func readPcapFile(filename string) <-chan gopacket.Packet {
// 	// Open file
// 	handle, err := pcap.OpenOffline(Join("", filename))
//  throwErr(err)
// 	defer handle.Close()
// 	return readPackets(handle)
// }

// func writePcapFile(deviceToRead, filename string, packetLimit int) {
// 	// Open output pcap file and write header
// 	f, _ := os.Create(Join("", filename))
// 	w := pcapgo.NewWriter(f)
// 	w.WriteFileHeader(uint32(snapshotLen), layers.LinkTypeEthernet)
// 	defer f.Close()

// 	packetCount := 0
// 	for packet := range readDevice(deviceToRead) { //packetSource.Packets() {
// 		w.WritePacket(packet.Metadata().CaptureInfo, packet.Data())

// 		// Only capture to limit and then stop
// 		packetCount++
// 		if packetCount > packetLimit {
// 			break
// 		}
// 	}
// }

// func readDevice(deviceToRead string) <-chan gopacket.Packet {
// 	// Open device
// 	handle, err := pcap.OpenLive(deviceToRead, snapshotLen, promiscuous, timeout)
//  throwErr(err)
// 	defer handle.Close()
// 	return readPackets(handle)
// }

// func readDeviceWithFilter(deviceToRead string) <-chan gopacket.Packet {
// 	// Open device
// 	handle, err := pcap.OpenLive(deviceToRead, snapshotLen, promiscuous, timeout)
//  throwErr(err)
// 	defer handle.Close()

// 	// Set filter
// 	var filter string = "tcp and port 80"
// 	if err := handle.SetBPFFilter(filter); err != nil {
// 		log.Fatal(err)
// 	}

// 	packetSource := gopacket.NewPacketSource(handle, handle.LinkType())
// 	for packet := range packetSource.Packets() {
// 		// Do something with a packet here.
// 		fmt.Println(packet)
// 	}

// }

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

// decode layer information in packet
// layer types available:
//    layers.
//      LayerTypeIPv4
//      LayerTypeIPv6
//      LayerTypeTCP
//      LayerTypeUDP
//      LayerTypeSCTP
//      LayerTypeICMPv4
//      LayerTypeICMPv6
//      LayerType

func printPacketInfo(packet gopacket.Packet) {

	// if we only want to support a subset of layer types:
	// var eth layers.Ethernet
	// var ip4 layers.IPv4
	// var ip6 layers.IPv6
	// var tcp layers.TCP
	// parser := gopacket.NewDecodingLayerParser(layers.LayerTypeEthernet, &eth, &ip4, &ip6, &tcp)
	// decoded := []gopacket.LayerType{}
	// throwErr(parser.DecodeLayers(packet.Data(), &decoded))
	// for _, layerType := range decoded {
	// 	switch layerType {
	// 	case layers.LayerTypeIPv6:
	// 		fmt.Println("    IP6 ", ip6.SrcIP, ip6.DstIP)
	// 	case layers.LayerTypeIPv4:
	// 		fmt.Println("    IP4 ", ip4.SrcIP, ip4.DstIP)
	// 		// case gopacket.UnsupportedLayerType:
	// 		// 	fmt.Println("    layer type not supported")
	// 	}
	// }

	fmt.Println("Layers:", packet.Layers())
	for _, layer := range packet.Layers() {
		lType := layer.LayerType()
		fmt.Println("layer type:", lType)
		// fmt.Println("lType decode:", lType.Decode([]byte, PacketBuilder)) // puts decoded data into packet builder
		// fmt.Println("lType contains:", lType.Contains(LayerType)) // LayerClass method returns bool
		// fmt.Println("lType layertypes:", lType.LayerTypes()) // LayerClass method
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
		// if lType.Contains(layers.LayerTypeEthernet) {
		// 	if ethernetLayer, ok := linkLayer.(*layers.Ethernet); ok {
		// 		fmt.Println("ethernet can decode:", ethernetLayer.CanDecode())
		// 		// fmt.Println("ethernet decode from bytes:", ethernetLayer.DecodeFromBytes(ethernetLayer.LayerPayload()), NilDecodeFeedback) // for changing the internal state of the layer
		// 		fmt.Println("ethernet next layer type:", ethernetLayer.NextLayerType())
		// 	}
		// }
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

	// Let's see if the packet is an ethernet packet
	// ethernetLayer := packet.Layer(layers.LayerTypeEthernet)
	// if ethernetLayer != nil {
	// 	fmt.Println("Ethernet layer detected.")
	// 	ethernetPacket, _ := ethernetLayer.(*layers.Ethernet)
	// 	fmt.Println("Source MAC: ", ethernetPacket.SrcMAC)
	// 	fmt.Println("Destination MAC: ", ethernetPacket.DstMAC)
	// 	// Ethernet type is typically IPv4 but could be ARP or other
	// 	fmt.Println("Ethernet type: ", ethernetPacket.EthernetType)
	// 	fmt.Println()
	// }

	// // Let's see if the packet is IP (even though the ether type told us)
	// ipLayer := packet.Layer(layers.LayerTypeIPv4)
	// if ipLayer != nil {
	// 	fmt.Println("IPv4 layer detected.")
	// 	ip, _ := ipLayer.(*layers.IPv4)

	// 	// IP layer variables:
	// 	// Version (Either 4 or 6)
	// 	// IHL (IP Header Length in 32-bit words)
	// 	// TOS, Length, Id, Flags, FragOffset, TTL, Protocol (TCP?),
	// 	// Checksum, SrcIP, DstIP
	// 	fmt.Printf("From %s to %s\n", ip.SrcIP, ip.DstIP)
	// 	fmt.Println("Protocol: ", ip.Protocol)
	// 	fmt.Println()
	// }

	// // Let's see if the packet is TCP
	// tcpLayer := packet.Layer(layers.LayerTypeTCP)
	// if tcpLayer != nil {
	// 	fmt.Println("TCP layer detected.")
	// 	tcp, _ := tcpLayer.(*layers.TCP)

	// 	// TCP layer variables:
	// 	// SrcPort, DstPort, Seq, Ack, DataOffset, Window, Checksum, Urgent
	// 	// Bool flags: FIN, SYN, RST, PSH, ACK, URG, ECE, CWR, NS
	// 	fmt.Printf("From port %d to %d\n", tcp.SrcPort, tcp.DstPort)
	// 	fmt.Println("Sequence number: ", tcp.Seq)
	// 	fmt.Println()
	// }

	// // Iterate over all layers, printing out each layer type
	// fmt.Println("All packet layers:")
	// for _, layer := range packet.Layers() {
	// 	fmt.Println("- ", layer.LayerType())
	// }

	// // When iterating through packet.Layers() above,
	// // if it lists Payload layer then that is the same as
	// // this applicationLayer. applicationLayer contains the payload
	// applicationLayer := packet.ApplicationLayer()
	// if applicationLayer != nil {
	// 	fmt.Println("Application layer/Payload found.")
	// 	fmt.Printf("%s\n", applicationLayer.Payload())

	// 	// Search for a string inside the payload
	// 	if strings.Contains(string(applicationLayer.Payload()), "HTTP") {
	// 		fmt.Println("HTTP found!")
	// 	}
	// }

	// // Check for errors
	// throwErr(packet.ErrorLayer().Error(), "Error decoding some part of the packet:")
}

func createPacketFromUnknownRawBytes() {
	// If we don't have a handle to a device or a file, but we have a bunch
	// of raw bytes, we can try to decode them in to packet information

	// NewPacket() takes the raw bytes that make up the packet as the first parameter
	// The second parameter is the lowest level layer you want to decode. It will
	// decode that layer and all layers on top of it. The third layer
	// is the type of decoding: default(all at once), lazy(on demand), and NoCopy
	// which will not create a copy of the buffer

	// Create an packet with ethernet, IP, TCP, and payload layers
	// We are creating one we know will be decoded properly but
	// your byte source could be anything. If any of the packets
	// come back as nil, that means it could not decode it in to
	// the proper layer (malformed or incorrect packet type)
	payload := []byte{2, 4, 6}
	options := gopacket.SerializeOptions{}
	buffer := gopacket.NewSerializeBuffer()
	gopacket.SerializeLayers(buffer, options,
		&layers.Ethernet{},
		&layers.IPv4{},
		&layers.TCP{},
		gopacket.Payload(payload),
	)
	rawBytes := buffer.Bytes()

	// Decode an ethernet packet
	ethPacket :=
		gopacket.NewPacket(
			rawBytes,
			layers.LayerTypeEthernet,
			gopacket.Default,
		)

	// with Lazy decoding it will only decode what it needs when it needs it
	// This is not concurrency safe. If using concurrency, use default
	ipPacket :=
		gopacket.NewPacket(
			rawBytes,
			layers.LayerTypeIPv4,
			gopacket.Lazy,
		)

	// With the NoCopy option, the underlying slices are referenced
	// directly and not copied. If the underlying bytes change so will
	// the packet
	tcpPacket :=
		gopacket.NewPacket(
			rawBytes,
			layers.LayerTypeTCP,
			gopacket.NoCopy,
		)

	fmt.Println(ethPacket)
	fmt.Println(ipPacket)
	fmt.Println(tcpPacket)
}

func createAndSendPacket(handle *pcap.Handle) {
	// Open device
	// handle, err = pcap.OpenLive(device, snapshotLen, promiscuous, timeout)
	// throwErr(err)
	// defer handle.Close()

	// Send raw bytes over wire
	rawBytes := []byte{10, 20, 30}
	err = handle.WritePacketData(rawBytes)
	throwErr(err)

	// Create a properly formed packet, just with
	// empty details. Should fill out MAC addresses,
	// IP addresses, etc.
	buffer := gopacket.NewSerializeBuffer()
	gopacket.SerializeLayers(buffer, options,
		&layers.Ethernet{},
		&layers.IPv4{},
		&layers.TCP{},
		gopacket.Payload(rawBytes),
	)
	outgoingPacket := buffer.Bytes()
	// Send our packet
	err = handle.WritePacketData(outgoingPacket)
	throwErr(err)

	// This time lets fill out some information
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
	// And create the packet with the layers
	buffer = gopacket.NewSerializeBuffer()
	gopacket.SerializeLayers(buffer, options,
		ethernetLayer,
		ipLayer,
		tcpLayer,
		gopacket.Payload(rawBytes),
	)
	outgoingPacket = buffer.Bytes()
}

// Create custom layer structure
type CustomLayer struct {
	// This layer just has two bytes at the front
	SomeByte    byte
	AnotherByte byte
	restOfData  []byte
}

// Register the layer type so we can use it
// The first argument is an ID. Use negative
// or 2000+ for custom layers. It must be unique
var CustomLayerType = gopacket.RegisterLayerType(
	2001,
	gopacket.LayerTypeMetadata{
		"CustomLayerType",
		gopacket.DecodeFunc(decodeCustomLayer),
	},
)

// When we inquire about the type, what type of layer should
// we say it is? We want it to return our custom layer type
func (l CustomLayer) LayerType() gopacket.LayerType {
	return CustomLayerType
}

// LayerContents returns the information that our layer
// provides. In this case it is a header layer so
// we return the header information
func (l CustomLayer) LayerContents() []byte {
	return []byte{l.SomeByte, l.AnotherByte}
}

// LayerPayload returns the subsequent layer built
// on top of our layer or raw payload
func (l CustomLayer) LayerPayload() []byte {
	return l.restOfData
}

// Custom decode function. We can name it whatever we want
// but it should have the same arguments and return value
// When the layer is registered we tell it to use this decode function
func decodeCustomLayer(data []byte, p gopacket.PacketBuilder) error {
	// AddLayer appends to the list of layers that the packet has
	p.AddLayer(&CustomLayer{data[0], data[1], data[2:]})

	// The return value tells the packet what layer to expect
	// with the rest of the data. It could be another header layer,
	// nothing, or a payload layer.

	// nil means this is the last layer. No more decoding
	// return nil

	// Returning another layer type tells it to decode
	// the next layer with that layer's decoder function
	// return p.NextDecoder(layers.LayerTypeEthernet)

	// Returning payload type means the rest of the data
	// is raw payload. It will set the application layer
	// contents with the payload
	return p.NextDecoder(gopacket.LayerTypePayload)
}

func efficientPacketDecode(packet gopacket.Packet) error {
	// Open device
	// handle, err = pcap.OpenLive(device, snapshotLen, promiscuous, timeout)
	// throwErr(err)
	// defer handle.Close()

	var arp layers.ARP
	var eth layers.Ethernet
	var ip4 layers.IPv4
	var ip6 layers.IPv6
	var tcp layers.TCP
	var udp layers.UDP
	var payload gopacket.Payload
	parser := gopacket.NewDecodingLayerParser(layers.LayerTypeEthernet, &eth, &arp, &ip4, &ip6, &tcp, &udp, &payload)
	decodedLayers := make([]gopacket.LayerType, 0, 10)
	// TODO: add dns
	if err := parser.DecodeLayers(packet.Data(), &decodedLayers); err != nil {
		return err
	}
	for _, typ := range decodedLayers {
		fmt.Println("Successfully decoded layer type:", typ)
		fmt.Println("type:", reflect.TypeOf(typ))
		switch typ {
		case layers.LayerTypeARP:
			fmt.Println("AddrType", arp.AddrType) // LinkType
			fmt.Println("Protocol", arp.Protocol) // EthernetType
			// TODO: consider this:
			// EthernetTypeLLC                         EthernetType = 0
			// EthernetTypeIPv4                        EthernetType = 0x0800
			// EthernetTypeARP                         EthernetType = 0x0806
			// EthernetTypeIPv6                        EthernetType = 0x86DD
			// EthernetTypeCiscoDiscovery              EthernetType = 0x2000
			// EthernetTypeNortelDiscovery             EthernetType = 0x01a2
			// EthernetTypeTransparentEthernetBridging EthernetType = 0x6558
			// EthernetTypeDot1Q                       EthernetType = 0x8100
			// EthernetTypePPPoEDiscovery              EthernetType = 0x8863
			// EthernetTypePPPoESession                EthernetType = 0x8864
			// EthernetTypeMPLSUnicast                 EthernetType = 0x8847
			// EthernetTypeMPLSMulticast               EthernetType = 0x8848
			// EthernetTypeEAPOL                       EthernetType = 0x888e
			// EthernetTypeQinQ                        EthernetType = 0x88a8
			// EthernetTypeLinkLayerDiscovery          EthernetType = 0x88cc
			// EthernetTypeEthernetCTP                 EthernetType = 0x9000
			fmt.Println("HwAddressSize", arp.HwAddressSize)         // uint8
			fmt.Println("ProtAddressSize", arp.ProtAddressSize)     // uint8
			fmt.Println("Operation", arp.Operation)                 // uint16
			fmt.Println("SourceHwAddress", arp.SourceHwAddress)     // []byte
			fmt.Println("SourceProtAddress", arp.SourceProtAddress) // []byte
			fmt.Println("DstHwAddress", arp.DstHwAddress)           // []byte
			fmt.Println("DstProtAddress", arp.DstProtAddress)       // []byte

		case layers.LayerTypeEthernet:
			fmt.Println("Eth", eth.SrcMAC, eth.DstMAC)
			fmt.Println("type -- if 802.3, length is set and type is 0. if not, length is 0 and type is 2048)", eth.EthernetType, eth.Length)
		case layers.LayerTypeIPv4:
			fmt.Println("Version", ip4.Version)
			fmt.Println("IHL", ip4.IHL)
			fmt.Println("TOS", ip4.TOS)
			fmt.Println("Length", ip4.Length)
			fmt.Println("Id", ip4.Id)
			if ip4.Flags > 0 {
				fmt.Println("Flags raw value:", ip4.Flags)
				if ip4.Flags&layers.IPv4EvilBit == layers.IPv4EvilBit {
					fmt.Println("\tthis packet has been marked unsafe! -- the evil bit is set (see http://tools.ietf.org/html/rfc3514)") //
				}
				if ip4.Flags&layers.IPv4DontFragment == layers.IPv4DontFragment {
					fmt.Println("\tthe 'don't fragment' flag is set")
				}
				if ip4.Flags&layers.IPv4MoreFragments == layers.IPv4MoreFragments {
					fmt.Println("\tthe 'more fragments' flag is set")
				}
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
			fmt.Println("AddressTo4", ip4.AddressTo4())
		case layers.LayerTypeIPv6:
			fmt.Println("IP6 ", ip6.SrcIP, ip6.DstIP)
			// methods to look at:
			// ipv6.AddressTo16()

			// available fields:
			// Version      uint8
			// TrafficClass uint8
			// FlowLabel    uint32
			// Length       uint16
			// NextHeader   IPProtocol
			// HopLimit     uint8
			// SrcIP        net.IP
			// DstIP        net.IP
			// HopByHop     *IPv6HopByHop
		case layers.LayerTypeTCP:
			fmt.Println("TCP ", tcp.SrcPort, tcp.DstPort)
			// methods to look at:
			// tcp.ComputeChecksum()
			// tcp.SrcPort.LayerType()
			// tcp.DstPort.LayerType()

			// available fields:
			// SrcPort, DstPort                           TCPPort
			// Seq                                        uint32
			// Ack                                        uint32
			// DataOffset                                 uint8
			// FIN, SYN, RST, PSH, ACK, URG, ECE, CWR, NS bool
			// Window                                     uint16
			// Checksum                                   uint16
			// Urgent                                     uint16
			// Options []TCPOption
			// fmt.Println("Options string", ip4.Options.String())
			// fmt.Println("Options type", ip4.Options.OptionType)
			// fmt.Println("Options type", ip4.Options.OptionType.String())
			// fmt.Println("Options length", ip4.Options.OptionLength)
			// fmt.Println("Options data", ip4.Options.OptionData)
			// Padding []byte
		case layers.LayerTypeUDP:
			fmt.Println("UDP", udp.SrcPort, udp.DstPort, udp.Length, udp.Checksum)
		case gopacket.LayerTypePayload:
			// fmt.Println("payload", payload.GoString())
			fmt.Println("payload", payload, payload.Payload())
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

	// packetSource := gopacket.NewPacketSource(handle, handle.LinkType())
	// for packet := range packetSource.Packets() {
	// 	parser := gopacket.NewDecodingLayerParser(
	// 		layers.LayerTypeEthernet,
	// 		&ethLayer,
	// 		&ipLayer,
	// 		&tcpLayer,
	// 	)
	// 	foundLayerTypes := []gopacket.LayerType{}

	// 	err := parser.DecodeLayers(packet.Data(), &foundLayerTypes)
	// 	throwErr(err, "Trouble decoding layers: ")

	// 	for _, layerType := range foundLayerTypes {
	// 		if layerType == layers.LayerTypeIPv4 {
	// 			fmt.Println("IPv4: ", ipLayer.SrcIP, "->", ipLayer.DstIP)
	// 		}
	// 		if layerType == layers.LayerTypeTCP {
	// 			fmt.Println("TCP Port: ", tcpLayer.SrcPort, "->", tcpLayer.DstPort)
	// 			fmt.Println("TCP SYN:", tcpLayer.SYN, " | ACK:", tcpLayer.ACK)
	// 		}
	// 	}
	// }
}

func main() {
	// If you create your own encoding and decoding you can essentially
	// create your own protocol or implement a protocol that is not
	// already defined in the layers package. In our example we are just
	// wrapping a normal ethernet packet with our own layer.
	// Creating your own protocol is good if you want to create
	// some obfuscated binary data type that was difficult for others
	// to decode

	// Finally, decode your packets:
	// rawBytes := []byte{0xF0, 0x0F, 65, 65, 66, 67, 68}
	// packet := gopacket.NewPacket(
	// 	rawBytes,
	// 	CustomLayerType,
	// 	gopacket.Default,
	// )
	// fmt.Println("Created packet out of raw bytes.")
	// fmt.Println(packet)

	// // Decode the packet as our custom layer
	// customLayer := packet.Layer(CustomLayerType)
	// if customLayer != nil {
	// 	fmt.Println("Packet was successfully decoded with custom layer decoder.")
	// 	customLayerContent, _ := customLayer.(*CustomLayer)
	// 	// Now we can access the elements of the custom struct
	// 	fmt.Println("Payload: ", customLayerContent.LayerPayload())
	// 	fmt.Println("SomeByte element:", customLayerContent.SomeByte)
	// 	fmt.Println("AnotherByte element:", customLayerContent.AnotherByte)
	// }

	if file {
		handle, err = pcap.OpenOffline(Join("", filename))
	} else { // from device
		handle, err = pcap.OpenLive(deviceToRead, snapshotLen, promiscuous, timeout)
	}
	throwErr(err)

	if filter {
		var bpf string = "tcp and port 80"
		throwErr(handle.SetBPFFilter(bpf))
	}

	// var f *os.File
	var w *pcapgo.Writer
	packetCount := 0
	if writeToFile { // TODO: fix scopes
		f, err := os.Create(Join("", filename))
		throwErr(err)
		w := pcapgo.NewWriter(f)
		w.WriteFileHeader(uint32(snapshotLen), layers.LinkTypeEthernet)
		defer f.Close()
	}

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
			fmt.Println(err)
			fmt.Println()
			fmt.Println()
			fmt.Println()
			fmt.Println()
			fmt.Println()
			fmt.Println()
			fmt.Println()
			fmt.Println()
			fmt.Println()
			printPacketInfo(packet)
		}
	}
}
