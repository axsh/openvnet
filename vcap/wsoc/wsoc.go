package wsoc

import (
	"log"
	"time"

	"github.com/axsh/pcap/utils"
	"github.com/gorilla/websocket"
)

const (
	// Time allowed to write a message to the peer.
	writeWait = 10 * time.Second

	// Time allowed to read the next pong message from the peer.
	PongWait = 60 * time.Second

	// Maximum supported network latency
	MaxLatency = 5 * time.Second

	// Send pings to peer with this period. Must be less than pongWait.
	pingPeriod = PongWait - MaxLatency

	// Maximum message size allowed from peer.
	// Vpacket.SnapshotLen + whatever else needs to be returned + json overhead
	// maxMessageSize = 2048
)

type con struct {
	*websocket.Conn
	in       chan []byte
	out      chan []byte
	isClosed bool
}

type WS interface {
	ThrowErr(error, ...string)
	In() chan []byte
	Out() chan []byte
	IsClosed() bool
}

func (ws *con) In() chan []byte {
	return ws.in
}

func (ws *con) Out() chan []byte {
	return ws.out
}

func (ws *con) IsClosed() bool {
	return ws.isClosed
}

func (ws *con) ThrowErr(err error, msg ...string) {
	if err != nil {
		ws.out <- []byte(
			utils.Join(
				utils.JoinWithSep(" ", msg...), err.Error(),
			),
		)
	}
}

// readData listens to the websocket ws and writes incoming messages to the ws.in chan
// Each websocket can only be read from by one process at a time, so some care
// has been taken to ensure that only one goroutine is reading from the websocket
// at any given time.
func (ws *con) readData() {
	utils.LimitedGo(func() {
		defer func() {
			if err := ws.Close(); err != nil {
				log.Println(err)
			}
			ws.isClosed = true
		}()

		// ws.SetReadLimit(maxMessageSize)
		ws.SetReadDeadline(time.Now().Add(PongWait))
		ws.SetPongHandler(func(string) error { ws.SetReadDeadline(time.Now().Add(PongWait)); return nil })
		for {
			_, message, err := ws.ReadMessage()
			if err != nil {
				log.Printf("error: %v", err)
				// if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
				// }
				break
			}
			ws.in <- message
		}
	})
}

// writeData sends data to the websocket ws from the ws.out chan
// Each websocket can only be written to by one process at a time, so some care
// has been taken to ensure that only one goroutine is writing to the websocket
// at any given time.
func (ws *con) writeData() {
	utils.LimitedGo(func() {
		ticker := time.NewTicker(pingPeriod)
		defer func() {
			ticker.Stop()
			if err := ws.Close(); err != nil {
				log.Println(err)
			}
			ws.isClosed = true
		}()
		for {
			select {
			case message, ok := <-ws.out:
				ws.SetWriteDeadline(time.Now().Add(writeWait))
				if !ok {
					ws.WriteMessage(websocket.CloseMessage, []byte{})
					return
				}

				w, err := ws.NextWriter(websocket.TextMessage)
				if err != nil {
					log.Println(err)
					return
				}
				w.Write(message)

				// Send queued messages
				n := len(ws.out)
				for i := 0; i < n; i++ {
					w.Write(<-ws.out)
				}

				if err := w.Close(); err != nil {
					log.Println(err)
					return
				}
			case <-ticker.C:
				ws.SetWriteDeadline(time.Now().Add(writeWait))
				if err := ws.WriteMessage(websocket.PingMessage, nil); err != nil {
					log.Println(err)
					return
				}
			}
		}
	})
}

// NewWS returns a new WS object with read and write chans already initialized
func NewWS(wsC *websocket.Conn) WS {
	ws := &con{
		Conn: wsC,
		// TODO: consider setting the size of these byte arrays
		// ws.in would be max sizeof(Vpacket) + json
		in:  make(chan []byte),
		out: make(chan []byte), // size == maxMessageSize
	}

	ws.readData()
	ws.writeData()

	return ws
}
