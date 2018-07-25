package main

import (
	"crypto/tls"
	"crypto/x509"
	"encoding/json"
	"flag"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"net/url"
	"os"
	"os/signal"
	"time"

	"github.com/axsh/openvnet/vcap/wsoc"
	"github.com/gorilla/websocket"
)

var addr = flag.String("addr", "localhost:8443", "http service address")

func init() {
	flag.Parse()
}

func main() {
	// load client cert
	cert, err := tls.LoadX509KeyPair("testdata/test_client.crt", "testdata/test_client.key")
	if err != nil {
		log.Fatal(err)
	}

	// load CA cert
	caCert, err := ioutil.ReadFile("testdata/testroot.crt")
	if err != nil {
		log.Fatal(err)
	}

	caCertPool := x509.NewCertPool()
	caCertPool.AppendCertsFromPEM(caCert)

	// setup HTTPS client
	tlsConfig := &tls.Config{
		Certificates: []tls.Certificate{cert},
		RootCAs:      caCertPool,
	}
	tlsConfig.BuildNameToCertificate()

	d := &websocket.Dialer{
		TLSClientConfig:  tlsConfig,
		Proxy:            http.ProxyFromEnvironment,
		HandshakeTimeout: 45 * time.Second,
	}

	u := url.URL{Scheme: "wss", Host: *addr, Path: "/pcap"}
	log.Printf("connecting to %s", u.String())

	wsC, _, err := d.Dial(u.String(), nil)
	if err != nil {
		log.Fatal("dial:", err)
	}
	defer wsC.Close()
	ws := wsoc.NewWS(wsC)
	// j, err := json.Marshal([]vpcap.Vpacket{
	j, err := json.Marshal([]map[string]interface{}{
		{
			"RequestID":   "not icmp",
			"Filter":      "not icmp",
			"SnapshotLen": 1538,
			// "Promiscuous":   true,
			"Timeout":     30 * time.Second,
			"Limit":       100,
			"IfaceToRead": "en3",
			// "ReadFile":      "",
			// "WriteFile":     "",
			// "SendRawPacket": true,
			// "SendMetadata":  true,
			"DecodePacket":       true,
			"DecodeProtocolData": true,
		},
		{
			"RequestID":          "icmp",
			"Filter":             "icmp",
			"SnapshotLen":        1538,
			"Timeout":            30 * time.Second,
			"Limit":              100,
			"IfaceToRead":        "en3",
			"DecodePacket":       true,
			"DecodeProtocolData": true,
		},
		{
			"Filter":             "icmp",
			"SnapshotLen":        1538,
			"Timeout":            30 * time.Second,
			"Limit":              100,
			"IfaceToRead":        "invalidDevice",
			"DecodePacket":       true,
			"DecodeProtocolData": true,
		},
		{
			"Filter":             "invalid filter",
			"SnapshotLen":        1538,
			"Timeout":            30 * time.Second,
			"Limit":              100,
			"IfaceToRead":        "en3",
			"DecodePacket":       true,
			"DecodeProtocolData": true,
		},
	})
	if err != nil {
		log.Println("marshal:", err)
		return
	}

	interrupt := make(chan os.Signal, 1)
	signal.Notify(interrupt, os.Interrupt)
	go func() {
		for {
			msg := <-ws.In()
			var decodedMsg map[string]interface{}
			if json.Valid(msg) {
				if err := json.Unmarshal(msg, &decodedMsg); err != nil {
					log.Fatal(err)
				}
				fmt.Println()
				fmt.Println("received:", decodedMsg)
			} else {
				fmt.Println("received:", string(msg))
			}
		}
	}()
	go func() {
		for {
			ws.Out() <- j
			time.Sleep(10 * time.Second)
		}
	}()

	for {
		select {
		case <-interrupt:
			log.Println("interrupt signal received from os")
			return
		}
	}
}
