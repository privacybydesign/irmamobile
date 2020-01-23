package main

import (
	"fmt"
	"os"

	"github.com/privacybydesign/irmamobile/irmagobridge"
)

type DummyBridge struct {
}

func (b *DummyBridge) DispatchFromGo(name string, payload string) {
	fmt.Println("Received action " + name + " with payload: " + payload)
}

func (b *DummyBridge) DebugLog(message string) {
	fmt.Println(message)
}

func main() {
	pwd, _ := os.Getwd()
	irmagobridge.Start(&DummyBridge{}, "/tmp", pwd)

	irmagobridge.DispatchFromNative("AppReadyEvent", "")
}
