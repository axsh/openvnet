package vpcap

import (
	"errors"
	"fmt"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/axsh/openvnet/vcap/utils"
	"github.com/axsh/openvnet/vcap/wsoc"
	"github.com/google/gopacket"
	"github.com/google/gopacket/pcap"
	"github.com/google/gopacket/pcapgo"
)

// standard packet sizes
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
	handle             *pcap.Handle //`json:"handle,omitempty"`
	w                  *pcapgo.Writer
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

func find() {
	// Find all ifaces
	ifaces, err := pcap.FindAllDevs()
	utils.CatchErr(err)

	// Print iface information
	// fmt.Println("Ifaces:", ifaces)
	fmt.Println("Ifaces found:")
	for _, iface := range ifaces {
		fmt.Println("\nName: ", iface.Name)
		fmt.Println("Description: ", iface.Description)
		fmt.Println("Ifaces addresses: ", iface.Description)
		for _, address := range iface.Addresses {
			fmt.Println("- IP address: ", address.IP)
			fmt.Println("- Subnet mask: ", address.Netmask)
		}
	}
}

func (vp *Vpacket) Validate(ws *wsoc.Con) bool {

	var err error

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
		ws.ThrowErr(err, "problem opening ", vp.ReadFile, ":")
	} else { // read from iface
		vp.handle, err = pcap.OpenLive(vp.IfaceToRead, vp.SnapshotLen, vp.Promiscuous, vp.Timeout)
		ws.ThrowErr(err, "problem reading ", vp.IfaceToRead, ":")
	}

	if vp.Filter != "" {
		// TODO: check syntax, etc...
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

		ws.ThrowErr(vp.handle.SetBPFFilter(vp.Filter))
	}

	// check if file exists
	if vp.WriteFile != "" {
		if _, err := os.Stat(vp.WriteFile); !os.IsNotExist(err) {
			ws.ThrowErr(err, vp.WriteFile, " already exists:")
			return false
		}
	}

	// check min, max
	if vp.SnapshotLen < 12 || vp.SnapshotLen > SuperJumboPacketMaxLen {
		ws.ThrowErr(errors.New(utils.Join("SnapshotLen must be between 12 and ",
			strconv.Itoa(int(SuperJumboPacketMaxLen)), " bytes.")))
	}

	// check min, max
	if vp.Timeout < wsoc.MaxLatency || vp.Timeout > wsoc.PongWait {
		ws.ThrowErr(errors.New(utils.Join("Timeout must be between ",
			strconv.Itoa(int(wsoc.MaxLatency)), " and ",
			strconv.Itoa(int(wsoc.PongWait)), " seconds.")))
	}

	//TODO: figure out better limits and implement time limits as well
	//check min, max
	if vp.Limit < 1 || vp.Limit > 10000 {
		ws.ThrowErr(errors.New(utils.Join(
			"Limit (the packet limit) must be between 1 and 10000 packets.")))
	}

	// // TODO: check against openvnet database
	// vp.IfaceToRead //string

	// if all of these are false, nothing would be processed
	if !vp.SendRawPacket && !vp.DecodePacket && !vp.SendMetadata {
		vp.DecodePacket = true
	}

	return true
}

func (vp *Vpacket) DoPcap(ws *wsoc.Con) {
	// find()

	if vp.WriteFile != "" {
		f, err := os.Create(utils.Join("", vp.WriteFile))
		if err != nil {
			ws.ThrowErr(err, "problem creating ", vp.WriteFile, ":")
			return
		}
		defer f.Close()
		vp.w = pcapgo.NewWriter(f)
		vp.w.WriteFileHeader(uint32(vp.SnapshotLen), vp.handle.LinkType())
	}

	fmt.Println(vp.handle)
	packetCount := 0
	for packet := range gopacket.NewPacketSource(vp.handle, vp.handle.LinkType()).Packets() {
		if ws.IsClosed {
			break
		}
		if vp.SendRawPacket {
			utils.LimitedGo(func() { ws.Out <- packet.Data() })
		}
		if vp.WriteFile != "" {
			utils.LimitedGo(func() { vp.w.WritePacket(packet.Metadata().CaptureInfo, packet.Data()) })
		}

		if vp.DecodePacket {
			utils.LimitedGo(func() {
				j := []byte{}
				if err := vp.efficientDecode(packet, &j); err != nil {
					if !strings.Contains(err.Error(), "No decoder for layer type") {
						ws.ThrowErr(err)
					}
					vp.generalDecode(packet, &j)
					fmt.Println()
				}
				fmt.Println(string(j))
				ws.Out <- j
			})
		}

		// Only capture to vp.Limit and then stop
		packetCount++
		if packetCount > vp.Limit {
			break
		}
		// fmt.Println(packetCount)
	}
}
