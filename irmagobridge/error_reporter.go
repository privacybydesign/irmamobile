package irmagobridge

import (
	"fmt"
	"github.com/go-errors/errors"
	"github.com/sirupsen/logrus"
)

type errorReporter struct{}

func (e *errorReporter) Levels() []logrus.Level {
	// For now, we only listen for warnings. Errors are currently handled via the ReportError handler.
	return []logrus.Level{logrus.WarnLevel}
}

func (e *errorReporter) Fire(entry *logrus.Entry) error {
	// Prevent that the bridge calls cause panics.
	defer func() {
		_ = recover()
	}()
	level := entry.Level.String()

	if entryErr, ok := entry.Data[logrus.ErrorKey]; ok {
		reportError(errors.WrapPrefix(entryErr, fmt.Sprintf("[%s] %s", level, entry.Message), 0), false)
		return nil
	}

	str, err := entry.String()
	if err != nil {
		return err
	}
	reportError(errors.WrapPrefix(str, fmt.Sprintf("[%s]", level), 0), false)
	return nil
}
