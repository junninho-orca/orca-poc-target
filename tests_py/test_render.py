"""Tests for the notification renderer.

Every assertion here holds on both the currently pinned Jinja2 and any later 3.1.x — these
test this module's behaviour, not the advisory. That is deliberate: a remediation runs this
suite *before* its change and again after, so a suite that failed on the pinned version would
make the baseline red and tell a remediator its change fixed something it did not touch.
"""
from __future__ import annotations

import pytest
from jinja2 import UndefinedError
from jinja2.exceptions import SecurityError

from notifier import render_notification, resolve_preferences
from notifier.render import DEFAULT_PREFERENCES, TemplateTooLargeError


def test_renders_a_simple_field():
    assert render_notification("Hello {{ name }}", {"name": "Ada"}) == "Hello Ada"


def test_renders_several_fields_and_literal_text():
    out = render_notification(
        "{{ greeting }}, {{ name }} — your invoice is {{ amount }}.",
        {"greeting": "Hi", "name": "Ada", "amount": "$12.00"},
    )
    assert out == "Hi, Ada — your invoice is $12.00."


def test_renders_a_loop_over_recipient_data():
    out = render_notification(
        "{% for item in items %}[{{ item }}]{% endfor %}", {"items": ["a", "b", "c"]}
    )
    assert out == "[a][b][c]"


def test_renders_a_conditional():
    template = "{% if urgent %}URGENT: {% endif %}{{ subject }}"
    assert render_notification(template, {"urgent": True, "subject": "x"}) == "URGENT: x"
    assert render_notification(template, {"urgent": False, "subject": "x"}) == "x"


def test_a_missing_field_raises_rather_than_rendering_blank():
    """A silently-empty field means someone receives a message with a hole in it."""
    with pytest.raises(UndefinedError):
        render_notification("Hello {{ name }}", {})


def test_a_template_with_no_placeholders_is_returned_as_is():
    assert render_notification("Scheduled maintenance tonight.") == (
        "Scheduled maintenance tonight."
    )


def test_a_none_template_is_rejected():
    with pytest.raises(ValueError):
        render_notification(None)


def test_an_oversized_template_is_rejected_before_compiling():
    with pytest.raises(TemplateTooLargeError):
        render_notification("x" * 20_001)


def test_a_template_at_the_size_limit_is_allowed():
    assert render_notification("x" * 20_000) == "x" * 20_000


def test_the_sandbox_blocks_reaching_python_internals():
    """The property this module's security rests on: a template author must not be able to
    walk from a supplied value into the interpreter."""
    with pytest.raises(SecurityError):
        render_notification("{{ data.__class__ }}", {"data": {}})


def test_the_sandbox_blocks_dunder_access_through_the_attr_filter():
    with pytest.raises(SecurityError):
        render_notification("{{ data | attr('__class__') }}", {"data": {}})


def test_preferences_fall_back_to_the_defaults():
    assert resolve_preferences(None) == DEFAULT_PREFERENCES
    assert resolve_preferences({}) == DEFAULT_PREFERENCES


def test_stated_preferences_override_the_defaults():
    resolved = resolve_preferences({"channel": "sms", "digest": True})
    assert resolved["channel"] == "sms"
    assert resolved["digest"] is True
    assert resolved["locale"] == DEFAULT_PREFERENCES["locale"]


def test_unknown_preference_keys_are_ignored():
    """An arbitrary payload must not be able to introduce a preference the service does not
    recognise."""
    resolved = resolve_preferences({"channel": "sms", "is_admin": True})
    assert "is_admin" not in resolved
    assert set(resolved) == set(DEFAULT_PREFERENCES)
