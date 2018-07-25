package main

// Note that this pcap api is artificially limited to only the devices
// registered in OpenVnet's database. OpenVnet can only see host OS interfaces
// -- i.e. real interfaces, host virtual interfaces, and virtual hypervisor
// interfaces. It will not be able to see non-hypervisor virtual devices created
// inside the guest (for example virtual devices sharing a single hypervisor
// bridge).

import (
	"crypto/tls"
	"crypto/x509"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"

	"golang.org/x/net/http2"

	"github.com/axsh/openvnet/vcap/utils"
	"github.com/axsh/openvnet/vcap/vpcap"
	"github.com/axsh/openvnet/vcap/wsoc"
	"github.com/gorilla/websocket"
)

func pcapApi(w http.ResponseWriter, r *http.Request) {
	upgrader := websocket.Upgrader{}
	wsC, err := upgrader.Upgrade(w, r, nil)
	ws := wsoc.NewWS(wsC)
	ws.ThrowErr(err, "upgrade:")
	for msg := range ws.In() {
		fmt.Println(string(msg))
		utils.LimitedGo(func() {
			var vps []vpcap.Vpacket
			json.Unmarshal(msg, &vps)
			// var vp vpcap.Vpacket
			// json.Unmarshal(msg, &vp)
			for _, vp := range vps {
				log.Println("received message:", vp)
				//TODO: can't close over vp in anonymous func as argument to LimitedGo
				// (if not passed explicitly, all values seem to be updated as the for loop progresses)
				// -- find a better workaround (vps[i] also doesn't work...) or allow utils.LimitedGo to pass in args
				utils.Limiter <- struct{}{}
				go func(vp vpcap.Vpacket) {
					defer func() { <-utils.Limiter }()
					if ok := vp.Validate(ws); ok {
						vp.DoPcap()
					}
				}(vp)
				// vp.DoPcap(msg, &ws)
			}
		})
	}
}

func main() {
	http.HandleFunc("/pcap", pcapApi)

	caCert, err := ioutil.ReadFile("testdata/test_client.crt")
	if err != nil {
		log.Fatal(err)
	}
	caCertPool := x509.NewCertPool()
	caCertPool.AppendCertsFromPEM(caCert)

	// setup HTTPS
	tlsConfig := &tls.Config{
		ClientCAs:  caCertPool,
		ClientAuth: tls.RequireAndVerifyClientCert,
	}
	tlsConfig.BuildNameToCertificate()

	server := &http.Server{
		Addr:      ":8443",
		TLSConfig: tlsConfig,
	}
	http2.ConfigureServer(server, nil)
	server.ListenAndServeTLS("testdata/test_server.crt", "testdata/test_server.key")
}
