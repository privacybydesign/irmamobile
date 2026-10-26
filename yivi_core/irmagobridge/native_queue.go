package irmagobridge

import "sync"

// nativeEvent is one event from the app, as DispatchFromNative got it.
type nativeEvent struct {
	name    string
	payload string
}

// eventQueue hands the events from the app to handle one at a time, in the
// order they came, on a goroutine of its own. The app calls in on its main
// thread, which on iOS and Android is also the thread its UI runs on (Flutter
// runs Dart there): handled right there, an event that reads the disk or the
// network (opening the client, installing a scheme, deleting a card) would
// freeze the app until it was done. One goroutine, not one per event, keeps
// the order the app relies on (AppReadyEvent first, the language before the
// cards are sent again).
//
// The queue grows as needed, so adding never waits.
type eventQueue struct {
	handle func(nativeEvent)

	mu      sync.Mutex
	pending []nativeEvent
	wake    chan struct{}
	start   sync.Once
}

func newEventQueue(handle func(nativeEvent)) *eventQueue {
	return &eventQueue{handle: handle, wake: make(chan struct{}, 1)}
}

// add puts e at the end of the queue and returns at once.
func (q *eventQueue) add(e nativeEvent) {
	q.start.Do(func() { go q.run() })
	q.mu.Lock()
	q.pending = append(q.pending, e)
	q.mu.Unlock()
	select {
	case q.wake <- struct{}{}:
	default: // already woken; the loop picks this one up too
	}
}

func (q *eventQueue) run() {
	for range q.wake {
		for {
			q.mu.Lock()
			if len(q.pending) == 0 {
				q.mu.Unlock()
				break
			}
			e := q.pending[0]
			q.pending[0] = nativeEvent{}
			q.pending = q.pending[1:]
			q.mu.Unlock()
			q.handle(e)
		}
	}
}
