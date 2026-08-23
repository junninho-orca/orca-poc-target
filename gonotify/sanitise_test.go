package gonotify

import (
	"errors"
	"strings"
	"testing"
)

func TestKeepsPlainText(t *testing.T) {
	out, err := Sanitise("<p>Your invoice is ready.</p>")
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(out, "Your invoice is ready.") {
		t.Fatalf("text was lost: %q", out)
	}
}

func TestDropsScriptElements(t *testing.T) {
	out, err := Sanitise("<p>hi</p><script>alert(1)</script>")
	if err != nil {
		t.Fatal(err)
	}
	if strings.Contains(out, "alert(1)") {
		t.Fatalf("script survived: %q", out)
	}
}

func TestDropsStyleElements(t *testing.T) {
	out, err := Sanitise("<style>p{}</style><p>hi</p>")
	if err != nil {
		t.Fatal(err)
	}
	if strings.Contains(out, "p{}") {
		t.Fatalf("style survived: %q", out)
	}
}

func TestDropsNestedScript(t *testing.T) {
	out, err := Sanitise("<div><span><script>bad()</script>ok</span></div>")
	if err != nil {
		t.Fatal(err)
	}
	if strings.Contains(out, "bad()") {
		t.Fatalf("nested script survived: %q", out)
	}
	if !strings.Contains(out, "ok") {
		t.Fatalf("sibling text was lost: %q", out)
	}
}

func TestNormalisesUnclosedTags(t *testing.T) {
	out, err := Sanitise("<p>one<p>two")
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(out, "one") || !strings.Contains(out, "two") {
		t.Fatalf("content lost: %q", out)
	}
}

func TestEmptyBodyIsAllowed(t *testing.T) {
	if _, err := Sanitise(""); err != nil {
		t.Fatal(err)
	}
}

func TestRejectsOversizedTemplate(t *testing.T) {
	_, err := Sanitise(strings.Repeat("x", MaxTemplateBytes+1))
	if !errors.Is(err, ErrTemplateTooLarge) {
		t.Fatalf("expected ErrTemplateTooLarge, got %v", err)
	}
}

func TestAllowsTemplateAtTheSizeLimit(t *testing.T) {
	if _, err := Sanitise(strings.Repeat("x", MaxTemplateBytes)); err != nil {
		t.Fatal(err)
	}
}

func TestPreservesEntities(t *testing.T) {
	out, err := Sanitise("<p>a &amp; b</p>")
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(out, "&amp;") {
		t.Fatalf("entity mangled: %q", out)
	}
}

func TestOutputIsWellFormed(t *testing.T) {
	out, err := Sanitise("<p>hi")
	if err != nil {
		t.Fatal(err)
	}
	for _, want := range []string{"<html>", "<body>", "</html>"} {
		if !strings.Contains(out, want) {
			t.Fatalf("expected %s in normalised output: %q", want, out)
		}
	}
}

func TestSanitiseIsIdempotent(t *testing.T) {
	once, err := Sanitise("<p>hi</p><script>x()</script>")
	if err != nil {
		t.Fatal(err)
	}
	twice, err := Sanitise(once)
	if err != nil {
		t.Fatal(err)
	}
	if once != twice {
		t.Fatalf("not idempotent:\n%q\n%q", once, twice)
	}
}

func TestMultipleScriptsAllRemoved(t *testing.T) {
	out, err := Sanitise("<script>a()</script><p>keep</p><script>b()</script>")
	if err != nil {
		t.Fatal(err)
	}
	if strings.Contains(out, "a()") || strings.Contains(out, "b()") {
		t.Fatalf("a script survived: %q", out)
	}
	if !strings.Contains(out, "keep") {
		t.Fatalf("content lost: %q", out)
	}
}
