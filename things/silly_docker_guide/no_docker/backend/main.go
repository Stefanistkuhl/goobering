package main

import (
	"crypto/rand"
	"fmt"
	"log"
	"math/big"
	"net/http"
)

func main() {
	messages := []string{
		"Hello from the Go backend!",
		"Greetings, world!",
		"Go is fun!",
		"This is a random message.",
		"Welcome to the message board!",
		"Another exciting message!",
	}

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

		w.Header().Set("Content-Type", "text/plain")
		fmt.Fprint(w, randomMessage)
	})

	port := "3000"
	log.Printf("Go backend listening on :%s", port)
	err := http.ListenAndServe(":"+port, nil)
	if err != nil {
		log.Fatal("Error starting Go backend: ", err)
	}
}
