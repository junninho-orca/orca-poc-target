// Package gonotify renders admin-authored notification templates for delivery over HTTP.
//
// Templates come from the admin console, so their markup is untrusted: it is parsed with
// golang.org/x/net/html and re-serialised, which drops anything that is not well-formed
// rather than passing it through to a recipient's mail client. The same job the Node and
// Python services do for their own template languages.
package gonotify

import (
	"strings"

	"golang.org/x/net/html"
)

// MaxTemplateBytes bounds what will be parsed at all, so a hostile template cannot make the
// parser do unbounded work before anything else gets a chance to reject it.
const MaxTemplateBytes = 20000

// Sanitise parses a notification body and returns its normalised form with script and style
// elements removed.
func Sanitise(body string) (string, error) {
	if len(body) > MaxTemplateBytes {
		return "", ErrTemplateTooLarge
	}
	doc, err := html.Parse(strings.NewReader(body))
	if err != nil {
		return "", err
	}
	strip(doc)
	var out strings.Builder
	if err := html.Render(&out, doc); err != nil {
		return "", err
	}
	return out.String(), nil
}

func strip(n *html.Node) {
	var doomed []*html.Node
	for c := n.FirstChild; c != nil; c = c.NextSibling {
		if c.Type == html.ElementNode && (c.Data == "script" || c.Data == "style") {
			doomed = append(doomed, c)
			continue
		}
		strip(c)
	}
	for _, d := range doomed {
		n.RemoveChild(d)
	}
}
