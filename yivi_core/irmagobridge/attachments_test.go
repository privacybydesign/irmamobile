package irmagobridge

import "testing"

// fakeBridge stands in for a native side. Named so a test failure says which
// attachment the events went to.
type fakeBridge struct{ name string }

func (f *fakeBridge) DispatchFromGo(name string, payload string) {}
func (f *fakeBridge) DebugLog(message string)                    {}

func reset() {
	attachments = nil
	nextAttachmentID = 0
	bridge = nil
}

func currentName(t *testing.T) string {
	t.Helper()
	if bridge == nil {
		return ""
	}
	f, ok := bridge.(*fakeBridge)
	if !ok {
		t.Fatalf("event sink is not a fakeBridge")
	}
	return f.name
}

func TestOneAttachmentDetachesAndTearsDown(t *testing.T) {
	reset()
	id := attach(&fakeBridge{name: "wallet"})
	if currentName(t) != "wallet" {
		t.Fatalf("events should go to the only attachment, got %q", currentName(t))
	}
	if !detach(id) {
		t.Fatal("detaching the only attachment must report that the last one went away")
	}
}

// The presentation Activity runs in its own task while the wallet's Activity is
// merely stopped, so both are attached. Events must follow the one the user is
// looking at.
func TestEventsFollowTheMostRecentAttachment(t *testing.T) {
	reset()
	attach(&fakeBridge{name: "wallet"})
	presentation := attach(&fakeBridge{name: "presentation"})

	if currentName(t) != "presentation" {
		t.Fatalf("events should go to the newest attachment, got %q", currentName(t))
	}

	if detach(presentation) {
		t.Fatal("the wallet is still attached, so this must not report a teardown")
	}
	if currentName(t) != "wallet" {
		t.Fatalf("events should fall back to the wallet, got %q", currentName(t))
	}
}

// The failure this bookkeeping exists to prevent: dismissing a credential
// request used to close the client out from under the Activity the user
// returns to.
func TestDetachingOneOfTwoDoesNotTearDown(t *testing.T) {
	reset()
	wallet := attach(&fakeBridge{name: "wallet"})
	presentation := attach(&fakeBridge{name: "presentation"})

	if detach(presentation) {
		t.Fatal("teardown reported while the wallet was still attached")
	}
	if !detach(wallet) {
		t.Fatal("teardown not reported when the last attachment went away")
	}
}

// Detach order is not guaranteed: the system can destroy the backgrounded
// wallet Activity while a credential request is on screen.
func TestDetachingOutOfOrderKeepsTheRemainingAttachment(t *testing.T) {
	reset()
	wallet := attach(&fakeBridge{name: "wallet"})
	attach(&fakeBridge{name: "presentation"})

	if detach(wallet) {
		t.Fatal("teardown reported while the presentation was still attached")
	}
	if currentName(t) != "presentation" {
		t.Fatalf("the presentation must keep receiving its own session, got %q", currentName(t))
	}
}

// An id from before a teardown, or a second detach of the same one, must not
// close a client that other attachments are using.
func TestUnknownIdDetachesNothing(t *testing.T) {
	reset()
	id := attach(&fakeBridge{name: "wallet"})

	if detach(id + 999) {
		t.Fatal("an unknown id must not report a teardown")
	}
	if currentName(t) != "wallet" {
		t.Fatalf("an unknown id must not move the event sink, got %q", currentName(t))
	}
	if !detach(id) {
		t.Fatal("the real id must still work afterwards")
	}
	if detach(id) {
		t.Fatal("detaching the same id twice must not report a second teardown")
	}
}

// Stop, which iOS uses, cannot name an attachment and pops the most recent.
func TestDetachLastUnwindsInOrder(t *testing.T) {
	reset()
	attach(&fakeBridge{name: "wallet"})
	attach(&fakeBridge{name: "presentation"})

	if detachLast() {
		t.Fatal("teardown reported while the wallet was still attached")
	}
	if currentName(t) != "wallet" {
		t.Fatalf("expected the wallet to receive events again, got %q", currentName(t))
	}
	if !detachLast() {
		t.Fatal("teardown not reported when the last attachment went away")
	}
	if detachLast() {
		t.Fatal("detaching from empty must not report a teardown")
	}
}

// A client started again after a teardown must not inherit attachments to
// natives that no longer exist.
func TestResetClearsAttachments(t *testing.T) {
	reset()
	attach(&fakeBridge{name: "wallet"})
	attach(&fakeBridge{name: "presentation"})
	resetAttachments()

	if len(attachments) != 0 {
		t.Fatalf("expected no attachments after a teardown, got %d", len(attachments))
	}
	if detachLast() {
		t.Fatal("detaching after a teardown must not report another one")
	}
}

// Ids must not be reused, or a stale detach would remove a live attachment.
func TestIdsAreNotReused(t *testing.T) {
	reset()
	first := attach(&fakeBridge{name: "a"})
	detach(first)
	second := attach(&fakeBridge{name: "b"})

	if second == first {
		t.Fatalf("attachment id %d was handed out twice", second)
	}
}
