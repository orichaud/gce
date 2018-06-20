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

var counter uint64

type Response struct {
	Status   string `json:"status"`
	Host     string `json:host`
	Response string `json:"response"`
}

func (response *Response) Send(writer http.ResponseWriter) error {
	data, err := json.Marshal(*response)
	if err != nil {
		return errors.New("Cannot serialize response")
		writer.WriteHeader(http.StatusInternalServerError)
	}
	fmt.Fprintf(writer, string(data))
	return nil
}

func HandleRequest(writer http.ResponseWriter, request *http.Request) {
	hostname, err := os.Hostname()
	if err != nil {
		panic(err)
	}

	start := time.Now()

	switch request.Method {
	case "GET":
		atomic.AddUint64(&counter, 1)
		response := &Response{
			Status:   "OK",
			Host:     hostname,
			Response: fmt.Sprintf("%d", atomic.LoadUint64(&counter))}
		err = response.Send(writer)
	default:
		error := &Response{
			Status: "KO",
			Host:   hostname}
		err = error.Send(writer)
	}

	if err != nil {
		log.Fatal(err)
		writer.WriteHeader(http.StatusInternalServerError)
	}
	elapsed := time.Since(start)
	log.Printf("Handling request: %s - %s ", request.Method, elapsed)
}

func main() {
	http.HandleFunc("/", HandleRequest)
	if err := http.ListenAndServe(":8080", nil); err != nil {
		log.Fatal("failed to start the HTTP web server", err)
	}
}
