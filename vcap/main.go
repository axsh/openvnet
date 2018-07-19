package main

// Note that this pcap api is artificially limited to only the devices
// registered in OpenVnet's database. OpenVnet can only see host OS interfaces
// -- i.e. real interfaces, host virtual interfaces, and virtual hypervisor
// interfaces. It will not be able to see non-hypervisor virtual devices created
// inside the guest (for example virtual devices sharing a single hypervisor
// bridge).

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"

	"github.com/axsh/openvnet/vcap/utils"
	"github.com/axsh/openvnet/vcap/vpcap"
	"github.com/axsh/openvnet/vcap/wsoc"
)

func pcapApi(w http.ResponseWriter, r *http.Request) {
	ws := wsoc.NewWS(w, r)
	for msg := range ws.In {
		fmt.Println(string(msg))
		utils.LimitedGo(func() {
			var vps []vpcap.Vpacket
			json.Unmarshal(msg, &vps)
			// var vp vpcap.Vpacket
			// json.Unmarshal(msg, &vp)
			for _, vp := range vps {
				log.Println("received message:", vp)
				//TODO: can't close over vp in anonymous func as argument to LimitedGo
				// -- find a workaround or allow utils.LimitedGo to pass in args
				// go func(vp vpcap.Vpacket) {
				//TODO: check the msg before DoPcap
				vp.DoPcap(msg, &ws)
				// }(vp)
				// vp.DoPcap(msg, &ws)
			}
		})
	}
}

func main() {
	http.HandleFunc("/pcap", pcapApi)
	log.Fatal(http.ListenAndServe("localhost:8080", nil))
}
