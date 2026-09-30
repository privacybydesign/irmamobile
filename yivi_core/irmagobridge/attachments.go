package irmagobridge

// ============================================================
// MORE THAN ONE NATIVE SIDE AT A TIME
// ============================================================
//
// The wallet client is a process singleton -- one encrypted database, one
// scheme configuration, one set of background jobs -- while the native side
// that drives it is per-Activity. For most of the app's life those are the same
// thing: one Activity, one Flutter engine, one attachment.
//
// A Digital Credentials API presentation breaks that. The platform starts the
// wallet's presentation Activity in its own task, so it can be on screen while
// the wallet's own Activity is merely stopped and still very much alive. Two
// natives, one client.
//
// Before this existed, that was corrupting rather than merely unsupported. Start
// assigned the package-level `bridge` unconditionally, so the second attachment
// silently took every Go event away from the first; and Stop tore the client
// down on any detach, so dismissing the presentation closed the wallet out from
// under the Activity the user would return to.
//
// So attachments are tracked:
//
//   - events go to the MOST RECENT attachment. While a presentation is on screen
//     it is the one with a user in front of it, and it is the one that has to
//     see the session it is driving.
//   - the client is torn down only when the LAST attachment goes away. Anything
//     else closes a database another Activity is still reading.
//
// Detach is by id rather than by comparing interface values: an attachment's
// bridge is a proxy for a Java or Swift object, and nothing promises that two
// proxies for the same object compare equal. The id is handed out by Start and
// given back by StopAttachment.

type attachment struct {
	id     int
	bridge IrmaMobileBridge
}

var attachments []attachment
var nextAttachmentID int

// attach records a native side and makes it the recipient of Go events,
// returning the id that detaches it again.
func attach(b IrmaMobileBridge) int {
	nextAttachmentID++
	attachments = append(attachments, attachment{id: nextAttachmentID, bridge: b})
	bridge = b
	return nextAttachmentID
}

// detach removes the attachment with the given id and reports whether the last
// one just went away, which is when the caller must tear the client down.
//
// An unknown id -- a double detach, or one from before a teardown -- removes
// nothing and reports false. Reporting true would close a client that other
// attachments are still using, which is the failure this whole file exists to
// prevent, so an unrecognised id is the one case where doing nothing is right.
func detach(id int) bool {
	for i, a := range attachments {
		if a.id == id {
			attachments = append(attachments[:i], attachments[i+1:]...)
			return retarget()
		}
	}
	return false
}

// detachLast removes the most recent attachment, for a native side that does not
// carry its id. Correct whenever attachments unwind in the order they were made,
// which is what a presentation does: it is started last and finishes first.
func detachLast() bool {
	if len(attachments) == 0 {
		return false
	}
	attachments = attachments[:len(attachments)-1]
	return retarget()
}

// retarget points the event sink at whatever attachment is now most recent, and
// reports whether none is left.
func retarget() bool {
	if len(attachments) == 0 {
		return true
	}
	bridge = attachments[len(attachments)-1].bridge
	return false
}

// resetAttachments drops all bookkeeping. Called as part of a teardown so a
// client started again afterwards does not inherit attachments to natives that
// no longer exist.
func resetAttachments() {
	attachments = nil
}
