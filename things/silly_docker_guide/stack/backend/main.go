package main

import (
	"crypto/rand"
	"fmt"
	"hash/fnv"
	"log"
	"math/big"
	"net/http"
	"os"
)

func colorFromHostname(hostname string) string {
	h := fnv.New32a()
	h.Write([]byte(hostname))
	colors := []string{
		"#FFB300",
		"#803E75",
		"#FF6800",
		"#A6BDD7",
		"#C10020",
		"#CEA262",
		"#817066",
		"#007D34",
		"#F6768E",
		"#00538A",
	}
	return colors[int(h.Sum32())%len(colors)]
}

func main() {
	messages := []string{
		"Hello from the Go backend!",
		"Greetings, world!",
		"Go is fun!",
		"This is a random message.",
		"Welcome to the message board!",
		"Another exciting message!",
	}

	hostname, _ := os.Hostname()
	color := colorFromHostname(hostname)
	http.HandleFunc("/message", func(w http.ResponseWriter, r *http.Request) {
		maxIndex := big.NewInt(int64(len(messages)))
		randomIndexBig, err := rand.Int(rand.Reader, maxIndex)
		if err != nil {
			log.Printf("Error generating random index: %v", err)
			http.Error(w, "Internal Server Error", http.StatusInternalServerError)
			return
		}
		randomIndex := int(randomIndexBig.Int64())

		randomMessage := messages[randomIndex]

		w.Header().Set("Content-Type", "application/json")
		fmt.Fprintf(w, `{"hostname":"%s","color":"%s","message":"%s"}`, hostname, color, randomMessage)
	})

	port := "3000"
	log.Printf("Go backend listening on :%s", port)
	err := http.ListenAndServe(":"+port, nil)
	if err != nil {
		log.Fatal("Error starting Go backend: ", err)
	}
}
