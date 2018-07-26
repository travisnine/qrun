package main

import (
	"bufio"
	"fmt"
	"os"
	"os/exec"
)

const BUFFER_SIZE = 1024 * 1024

var myArgs []string
var myArgsIdx []int
var myQueue chan string = make(chan string, BUFFER_SIZE)
var queueDone chan byte = make(chan byte)

func qRunner() {
	for qItem := range myQueue {
		for _, x := range myArgsIdx {
			myArgs[x] = qItem
		}
		fmt.Printf("Running: %v\n", myArgs)
		cmd := exec.Command(myArgs[0], myArgs[1:]...)
		cmd.Stdout = os.Stdout
		cmd.Stderr = os.Stderr
		cmd.Run()
	}
	queueDone <- 1
}

func main() {
	if len(os.Args) < 3 {
		fmt.Printf("Usage: %v program {}\n", os.Args[0])
		return
	}
	myArgs = os.Args[1:]
	fmt.Printf("Args: %v\n", myArgs)
	for idx, elem := range myArgs {
		if elem == "{}" {
			myArgsIdx = append(myArgsIdx, idx)
		}
	}
	if len(myArgsIdx) < 1 {
		fmt.Println("WARNING: You haven't included any {} in the arugment list")
	}
	go qRunner()
	scanner := bufio.NewScanner(os.Stdin)
	for scanner.Scan() {
		text := scanner.Text()
		if text == "" {
			continue
		}
		if text[0] == 4 {
			break
		}
		myQueue <- text
		fmt.Printf("Added: %v\n", text)
	}
	fmt.Println("EOF Reached")
	close(myQueue)
	<-queueDone
	return
}
