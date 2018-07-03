package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"log"
	"net/http"
	"os"
	"sync/atomic"
	"time"
)

// This is the structure whcih contains the counter. it must be atomically incremented.
type counter struct {
	count uint64
}

// Simple atomic increment of the counter
func (c *counter) Incr() uint64 {
	return atomic.AddUint64(&c.count, 1)
}

// This is the structure which is marshalled as JSON
type response struct {
	Status   string `json:"status"`
	Host     string `json:"host"`
	Response string `json:"response,omitempty"`
}

// Simple function to send a JSON output of the response
func (r *response) Send(w http.ResponseWriter) error {
	data, err := json.Marshal(*r)
	if err != nil {
		return errors.New("Cannot serialize response")
	}
	fmt.Fprintf(w, string(data))
	return nil
}

// Request handler. It incrmeents the counter and send a JSON response.
// Only HTTP GET is answered, an error is otherwise returned to the caller.
// the repsonse contains the incremented counter.
func handleRequest(c *counter, w http.ResponseWriter, r *http.Request) {
	hostname, err := os.Hostname()
	if err != nil {
		panic(err)
	}

	start := time.Now()

	switch r.Method {
	case "GET":
		resp := &response{
			Status:   "OK",
			Host:     hostname,
			Response: fmt.Sprintf("%d", c.Incr())}
		err = resp.Send(w)
	default:
		resp := &response{
			Status: "KO",
			Host:   hostname}
		w.WriteHeader(http.StatusMethodNotAllowed)
		err = resp.Send(w)
	}

	if err != nil {
		log.Fatal(err)
		w.WriteHeader(http.StatusInternalServerError)
	}
	elapsed := time.Since(start)
	log.Printf("Handling request: %s - %s ", r.Method, elapsed)
}

// Probe handler for liveness and readiness. Used only by Kubernetes.
func handleLiveness(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("X-Liveness", "alive")
	w.Write([]byte("ok"))
}

func main() {
	c := &counter{count: 0}
	http.HandleFunc("/counter", func(w http.ResponseWriter, r *http.Request) {
		handleRequest(c, w, r)
	})
	http.HandleFunc("/healthz", handleLiveness)

	if err := http.ListenAndServe(":8080", nil); err != nil {
		log.Fatal("failed to start the HTTP web server", err)
	}
}
