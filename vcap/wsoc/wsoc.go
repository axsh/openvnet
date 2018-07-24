package wsoc

import (
	"log"
	"net/http"
	"time"

	"github.com/axsh/openvnet/vcap/utils"
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

type Con struct {
	*websocket.Conn
	In       chan []byte
	Out      chan []byte
	IsClosed bool
}

// type Con interface {
// 	ThrowErr(error, ...string)
// }

func (ws *Con) ThrowErr(err error, msg ...string) {
	if err != nil {
		ws.Out <- []byte(
			utils.Join(
				utils.JoinWithSep(" ", msg...), err.Error(),
			),
		)
	}
}

// ReadData listens to the websocket ws and writes incoming messages to the ws.In chan
// Each websocket can only be read from by one process at a time, so some care
// has been taken to ensure that only one goroutine is reading from the websocket
// at any given time.
func (ws *Con) ReadData() {
	utils.LimitedGo(func() {
		defer func() {
			if err := ws.Close(); err != nil {
				log.Println(err)
			}
			ws.IsClosed = true
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
			ws.In <- message
		}
	})
}

// WriteData sends data to the websocket ws from the ws.Out chan
// Each websocket can only be written to by one process at a time, so some care
// has been taken to ensure that only one goroutine is writing to the websocket
// at any given time.
func (ws *Con) WriteData() {
	utils.LimitedGo(func() {
		ticker := time.NewTicker(pingPeriod)
		defer func() {
			ticker.Stop()
			if err := ws.Close(); err != nil {
				log.Println(err)
			}
			ws.IsClosed = true
		}()
		for {
			select {
			case message, ok := <-ws.Out:
				ws.SetWriteDeadline(time.Now().Add(writeWait))
				if !ok {
					// The channel was closed.
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
				n := len(ws.Out)
				for i := 0; i < n; i++ {
					w.Write(<-ws.Out)
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

// NewWS returns a new Con object with read and write chans already initialized
func NewWS(w http.ResponseWriter, r *http.Request) *Con {
	upgrader := websocket.Upgrader{}
	wsC, err := upgrader.Upgrade(w, r, nil)
	ws := &Con{
		Conn: wsC,
		// TODO: consider setting the size of these byte arrays
		// ws.In would be max sizeof(Vpacket) + json
		In:  make(chan []byte),
		Out: make(chan []byte), // size == maxMessageSize
	}
	ws.ThrowErr(err, "upgrade:")

	ws.ReadData()
	ws.WriteData()

	return ws
}
