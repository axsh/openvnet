package vpcap

import (
	"encoding/json"
	"errors"
	"fmt"
	"net"
	"os"
	"strconv"
	"strings"
	"time"

	customLayers "github.com/axsh/openvnet/vcap/layers"
	"github.com/axsh/openvnet/vcap/utils"
	"github.com/axsh/openvnet/vcap/wsoc"
	"github.com/google/gopacket"
	"github.com/google/gopacket/layers"
	"github.com/google/gopacket/pcap"
	"github.com/google/gopacket/pcapgo"
)

// standard packet sizes*
const (
	StandardPacketMaxLen   int32 = 1538
	BabyGiantPacketMaxLen  int32 = 1600
	JumboPacketMaxLen      int32 = 9038
	SuperJumboPacketMaxLen int32 = 65535

	// the following would have to be edited in the pcap lib to
	// work with a uint32 instead of the int32 that it expects:
	// ipv6JumbogramPacketMaxLen uint32 = 4294967295
)

type Vpacket struct {
	handle    *pcap.Handle //`json:"handle,omitempty"`
	w         *pcapgo.Writer
	ws        wsoc.WS
	packetNum string

	RequestID          string        `json:"requestid,omitempty"`
	Filter             string        `json:"filter,omitempty"`
	SnapshotLen        int32         `json:"snapshotLen,omitempty"`
	Promiscuous        bool          `json:"promiscuous,omitempty"`
	Timeout            time.Duration `json:"timeout,omitempty"`
	Limit              int           `json:"limit,omitempty"`
	IfaceToRead        string        `json:"ifaceToRead,omitempty"`
	ReadFile           string        `json:"readFile,omitempty"`
	WriteFile          string        `json:"writeFile,omitempty"`
	SendRawPacket      bool          `json:"sendRawPacket,omitempty"`
	SendMetadata       bool          `json:"sendMetadata,omitempty"`
	DecodePacket       bool          `json:"decodePacket,omitempty"`
	DecodeProtocolData bool          `json:"decodeProtocolData,omitempty"`
}

// readIface checks to see if the device named IfaceToRead can be read.
func (vp *Vpacket) readIface() error {
	// Find all ifaces
	ifaces, err := pcap.FindAllDevs()
	if err != nil {
		return err
	}

	// Print iface information
	// fmt.Println("Ifaces:", ifaces)
	// fmt.Println("Ifaces found:")
	for _, iface := range ifaces {
		if strings.Contains(iface.Name, vp.IfaceToRead) {
			return nil
		}
		// fmt.Println("\nName: ", iface.Name)
		// fmt.Println("Description: ", iface.Description)
		// fmt.Println("Ifaces addresses: ", iface.Description)
		// for _, address := range iface.Addresses {
		// 	fmt.Println("- IP address: ", address.IP)
		// 	fmt.Println("- Subnet mask: ", address.Netmask)
		// }
	}
	return errors.New(utils.Join("could not find ", vp.IfaceToRead))
}

func (vp *Vpacket) createAndSendTCPpacket(rawBytes []byte) error {
	buffer := gopacket.NewSerializeBuffer()
	var options gopacket.SerializeOptions
	gopacket.SerializeLayers(buffer, options,
		&layers.Ethernet{
			SrcMAC: net.HardwareAddr{0xFF, 0xAA, 0xFA, 0xAA, 0xFF, 0xAA},
			DstMAC: net.HardwareAddr{0xBD, 0xBD, 0xBD, 0xBD, 0xBD, 0xBD},
		},
		&layers.IPv4{
			SrcIP: net.IP{127, 0, 0, 1},
			DstIP: net.IP{8, 8, 8, 8},
		},
		&layers.TCP{
			SrcPort: layers.TCPPort(4321),
			DstPort: layers.TCPPort(80),
		},
		gopacket.Payload(rawBytes),
	)

	if err := vp.handle.WritePacketData(buffer.Bytes()); err != nil {
		return err
	}

	return nil
}

// createAndSendModbusPacket creates and sends a modbus packet using modbus
// packet data (including the payload data) with the option to include an
// ethernet layer. It will be sent on the device in vp.handle.
func (vp *Vpacket) createAndSendModbusPacket(rawBytes []byte,
	ethLayer ...*layers.Ethernet) error {
	if len(ethLayer) > 1 {
		return errors.New("error creating modbus packet: " +
			"a maximum of one ethLayer is supported at this time")
	}
	modbusLayer := &customLayers.Modbus{}
	if err := modbusLayer.DecodeFromBytes(rawBytes, gopacket.NilDecodeFeedback); err != nil {
		return err
	}

	buffer := gopacket.NewSerializeBuffer()
	var options gopacket.SerializeOptions
	if len(ethLayer) != 0 {
		gopacket.SerializeLayers(buffer, options,
			ethLayer[0],
			modbusLayer,
			gopacket.Payload(modbusLayer.Payload),
		)
	} else {
		gopacket.SerializeLayers(buffer, options,
			modbusLayer,
			gopacket.Payload(modbusLayer.Payload),
		)
	}

	if err := vp.handle.WritePacketData(buffer.Bytes()); err != nil {
		return err
	}

	return nil
}

func (vp *Vpacket) sendRawPacket(rawBytes []byte) error {
	// for packets formed elsewhere --
	// or just raw data...better hope it has an address somewhere!
	// vp.handle.WritePacketData(rawBytes)
	// to make this safer, it could be checked with something like:
	packet := gopacket.NewPacket(
		rawBytes,
		vp.handle.LinkType(),
		gopacket.Default,
	)
	vp.handle.WritePacketData(packet.Data())

	return nil
}

// TODO: check whether an identical pcap is already running -- if so, don't do anything
func (vp *Vpacket) Validate(ws wsoc.WS) bool {

	var err error

	vp.ws = ws

	if vp.RequestID == "" {
		vp.RequestID = utils.RandString(4)
	}

	if vp.Filter != "" {
		// TODO: set up common filter templates to be called easily from the api.
		// e.g. to find start and stop session packets

		// subnet can be dotted quad, triple, double, or single -- the netmask will
		// be set accordingly (i.e. a quad gets a mask of 255.255.255.255, a triple
		// gets 255.255.255.0, a double is 255.255.0.0, and single 255.0.0.0)
		// vp.Filter = "net 192.168"

		// more specific mask with e.g.:
		// vp.Filter = "net 192.168 mask 63.87.0.0" // ( 63==^uint8(192) and 87==^uint8(168) )

		// src and dst can be set independently like so:
		// vp.Filter = "src net 192.168 and dst net 192"

		// vp.Filter = "icmp"
		// vp.Filter = "ip6"
		// vp.Filter = ""

		if err := vp.handle.SetBPFFilter(vp.Filter); err != nil {
			ws.ThrowErr(err, "problem setting filter ", vp.Filter, ": ")
			return false
		}
	}

	// check if file exists
	if vp.WriteFile != "" {
		if _, err := os.Stat(vp.WriteFile); !os.IsNotExist(err) {
			ws.ThrowErr(err, vp.WriteFile, " already exists: ")
			return false
		}
	}

	if vp.SnapshotLen == 0 {
		vp.SnapshotLen = StandardPacketMaxLen
	} else {
		// check min, max
		if vp.SnapshotLen < 12 || vp.SnapshotLen > SuperJumboPacketMaxLen {
			ws.ThrowErr(errors.New(utils.Join("SnapshotLen must be between 12 and ",
				strconv.Itoa(int(SuperJumboPacketMaxLen)), " bytes.")))
			return false
		}
	}

	if vp.Timeout == 0 {
		vp.Timeout = time.Duration(30 * time.Second)
	} else {
		// check min, max
		if vp.Timeout < wsoc.MaxLatency || vp.Timeout > wsoc.PongWait {
			ws.ThrowErr(errors.New(utils.Join("Timeout must be between ",
				strconv.Itoa(int(wsoc.MaxLatency)), " and ",
				strconv.Itoa(int(wsoc.PongWait)), " seconds.")))
			return false
		}
	}

	if vp.ReadFile != "" {
		// check if file exists
		if _, err := os.Stat(vp.ReadFile); err != nil {
			if os.IsNotExist(err) {
				ws.ThrowErr(err, vp.ReadFile, " does not exist:")
				return false
			}
			ws.ThrowErr(err, "problem reading ", vp.ReadFile, ":")
			return false
		}
		vp.handle, err = pcap.OpenOffline(vp.ReadFile)
		if err != nil {
			ws.ThrowErr(err, "problem opening ", vp.ReadFile, ":")
			return false
		}
	} else { // read from iface
		vp.handle, err = pcap.OpenLive(vp.IfaceToRead, vp.SnapshotLen, vp.Promiscuous, vp.Timeout)
		fmt.Println(vp.handle)
		if err != nil {
			ws.ThrowErr(err, "problem reading ", vp.IfaceToRead, ":")
			return false
		}
	}

	//TODO: figure out better limits and implement time limits as well
	// check min, max
	if vp.Limit < 0 || vp.Limit > 9999 {
		ws.ThrowErr(errors.New(utils.Join(
			"Limit (the packet limit) must be between 0 and 10000 packets.")))
		return false
	}

	// TODO: check against openvnet database (the handle check covers the current readIface functionality)
	if err := vp.readIface(); err != nil {
		ws.ThrowErr(err)
		return false
	}

	// if all of these are false, nothing would be processed
	if !vp.SendRawPacket && !vp.DecodePacket && !vp.SendMetadata {
		ws.ThrowErr(errors.New("at least one of SendRawPacket, DecodePacket, or SendMetadata must be true"))
		return false
	}

	return true
}

// DoPcap captures packets according to the values in the Vpacket structure
// that vp point to. Only pcap linktypes are supported
// (see https://godoc.org/github.com/google/gopacket/layers#LinkType)
func (vp *Vpacket) DoPcap() {
	if vp.WriteFile != "" {
		f, err := os.Create(utils.Join("", vp.WriteFile))
		if err != nil {
			vp.ws.ThrowErr(err, "problem creating ", vp.WriteFile, ":")
			return
		}
		defer f.Close()
		vp.w = pcapgo.NewWriter(f)
		vp.w.WriteFileHeader(uint32(vp.SnapshotLen), vp.handle.LinkType())
	}

	fmt.Println(vp.handle)

	// TODO: figure this out for "efficientDecode" as it should be much more efficient.
	// it might also prevent skipping packets -- TODO: check to see if we are skipping packets
	// data, _, _ := vp.handle.ZeroCopyReadPacketData()
	// fmt.Println(data)

	packetCount := 0
	// TODO: test to make sure that EOF in a packet doesn't break out of the loop
	for packet := range gopacket.NewPacketSource(vp.handle, vp.handle.LinkType()).Packets() {
		// for {
		if vp.ws.IsClosed() {
			break
		}
		vp.packetNum = strconv.Itoa(packetCount)
		if vp.SendRawPacket {
			// data, _, err := vp.handle.ZeroCopyReadPacketData()
			// vp.ws.ThrowErr(err, "problem sending raw packet from ", vp.IfaceToRead, ":")
			// utils.LimitedGo(func() { vp.ws.Out() <- data })
			utils.LimitedGo(func() { vp.ws.Out() <- packet.Data() })
		}
		if vp.WriteFile != "" {
			// data, captureInfo, err := vp.handle.ZeroCopyReadPacketData()
			// vp.ws.ThrowErr(err, "problem writing packet from ", vp.IfaceToRead, " to file ", vp.WriteFile, ":")
			// utils.LimitedGo(func() { vp.w.WritePacket(captureInfo, data) })
			utils.LimitedGo(func() { vp.w.WritePacket(packet.Metadata().CaptureInfo, packet.Data()) })
		}

		if vp.DecodePacket {
			// utils.LimitedGo(func() {
			j := &[]byte{}
			if err := vp.efficientDecode(packet, j); err != nil {
				// if err := vp.efficientDecode(j); err != nil {
				if !strings.Contains(err.Error(), "No decoder for layer type") {
					vp.ws.ThrowErr(err)
				}
				vp.ws.ThrowErr(vp.generalDecode(packet, j))
				// vp.ws.ThrowErr(vp.generalDecode(<-gopacket.NewPacketSource(vp.handle,
				// 	vp.handle.LinkType()).Packets(), j))
			}
			if len(*j) != 0 {
				// fmt.Println(string(*j))
				// fmt.Println()
				vp.ws.Out() <- *j
			}
			// })
		} else if vp.SendMetadata {
			j, err := json.Marshal(packet.Metadata())
			vp.ws.ThrowErr(err)
			utils.LimitedGo(func() { vp.ws.Out() <- j })
		}

		if vp.Limit != 0 {
			// Only capture to vp.Limit and then stop
			packetCount++
			if packetCount > vp.Limit {
				break
			}
		}
		// fmt.Println(packetCount)
	}
}
