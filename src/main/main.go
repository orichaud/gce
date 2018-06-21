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

type counter struct {
	count uint64
}

func (c *counter) Incr() uint64 {
	return atomic.AddUint64(&c.count, 1)
}

type response struct {
	Status   string `json:"status"`
	Host     string `json:"host"`
	Response string `json:"response,omitempty"`
}

func (r *response) Send(w http.ResponseWriter) error {
	data, err := json.Marshal(*r)
	if err != nil {
		return errors.New("Cannot serialize response")
	}
	fmt.Fprintf(w, string(data))
	return nil
}

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
