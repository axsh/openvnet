package main

import (
	"encoding/json"
	"flag"
	"log"
	"net/url"
	"os"
	"os/signal"
	"time"

	"github.com/axsh/openvnet/vcap/vpcap"
	"github.com/axsh/openvnet/vcap/wsoc"
	"github.com/gorilla/websocket"
)

var addr = flag.String("addr", "localhost:8080", "http service address")

func main() {
	flag.Parse()

	u := url.URL{Scheme: "ws", Host: *addr, Path: "/pcap"}
	log.Printf("connecting to %s", u.String())

	wsC, _, err := websocket.DefaultDialer.Dial(u.String(), nil)
	if err != nil {
		log.Fatal("dial:", err)
	}
	defer wsC.Close()
	ws := wsoc.Con{
		Conn: wsC,
		In:   make(chan []byte),
		Out:  make(chan []byte),
	}
	ws.ThrowErr(err, "upgrade:")
	ws.ReadData()
	ws.WriteData()
	j, err := json.Marshal([]vpcap.Vpacket{
		{
			Handle: nil, // zero value is ignored
			Filter: "icmp",
			// Filter:             "eth",
			SnapshotLen:        1538,
			Promiscuous:        false, // zero value is ignored
			Timeout:            30 * time.Second,
			Limit:              100,
			IfaceToRead:        "en3",
			ReadFile:           "",    // zero value is ignored
			WriteFile:          "",    // zero value is ignored
			SendRawPacket:      false, // zero value is ignored
			DecodePacket:       true,
			DecodeProtocolData: true,
		},
		// {
		// 	Filter:             "icmp",
		// 	SnapshotLen:        1538,
		// 	Timeout:            30 * time.Second,
		// 	Limit:              100,
		// 	IfaceToRead:        "vboxnet0",
		// 	DecodePacket:       true,
		// 	DecodeProtocolData: true,
		// },
	})
	if err != nil {
		log.Println("marshal:", err)
		return
	}

	interrupt := make(chan os.Signal, 1)
	signal.Notify(interrupt, os.Interrupt)
	go func() {
		for {
			log.Println("received:", string(<-ws.In))
		}
	}()
	go func() {
		for {
			ws.Out <- j
			time.Sleep(10 * time.Second)
		}
	}()

	for {
		select {
		case <-interrupt:
			log.Println("interrupt signal received from os")
			ws.Close()
			return
		}
	}
}
