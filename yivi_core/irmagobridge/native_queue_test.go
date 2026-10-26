package irmagobridge

import (
	"fmt"
	"sync"
	"testing"
	"time"
)

func TestEventQueueKeepsOrderAndDoesNotWait(t *testing.T) {
	var (
		mu      sync.Mutex
		handled []string
		done    = make(chan struct{})
		release = make(chan struct{})
	)
	const n = 1000
	q := newEventQueue(func(e nativeEvent) {
		if e.name == "0" {
			<-release // the first event takes long
		}
		mu.Lock()
		handled = append(handled, e.name)
		if len(handled) == n {
			close(done)
		}
		mu.Unlock()
	})

	start := time.Now()
	for i := 0; i < n; i++ {
		q.add(nativeEvent{name: fmt.Sprint(i)})
	}
	// Adding returned while the first event was still being handled.
	if waited := time.Since(start); waited > time.Second {
		t.Fatalf("adding waited %s for the handler", waited)
	}
	close(release)

	select {
	case <-done:
	case <-time.After(5 * time.Second):
		t.Fatal("not every event was handled")
	}
	for i, name := range handled {
		if name != fmt.Sprint(i) {
			t.Fatalf("event %d handled as number %s", i, name)
		}
	}
}
