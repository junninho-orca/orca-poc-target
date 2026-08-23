package gonotify

import "errors"

// ErrTemplateTooLarge is returned before parsing, so an oversized template never reaches the
// parser at all.
var ErrTemplateTooLarge = errors.New("gonotify: template exceeds MaxTemplateBytes")
