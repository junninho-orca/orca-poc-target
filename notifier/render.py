"""Renders admin-authored notification templates with per-recipient data.

The Python counterpart of `src/notification.js`, which does the same job with lodash's
`_.template()`.

**Why the sandbox matters here.** Templates are authored in the admin console, not shipped
with the code, so they are treated as untrusted input. They are rendered through Jinja2's
`SandboxedEnvironment` rather than a plain `Environment`, which is what is meant to stop a
template author reaching Python attributes, builtins, or the interpreter behind the renderer.
The security of this module is therefore only as good as that sandbox is in the pinned
version of Jinja2 — which is exactly what makes a sandbox-escape advisory against it relevant
rather than theoretical.
"""
from __future__ import annotations

from jinja2 import StrictUndefined
from jinja2.sandbox import SandboxedEnvironment

_MAX_TEMPLATE_CHARS = 20_000

DEFAULT_PREFERENCES = {"channel": "email", "digest": False, "locale": "en-US"}


class TemplateTooLargeError(ValueError):
    """Raised before compiling, so a hostile template never reaches the parser."""


def _environment() -> SandboxedEnvironment:
    return SandboxedEnvironment(undefined=StrictUndefined, autoescape=False)


def render_notification(template: str, data: dict | None = None) -> str:
    """Render one notification body.

    `StrictUndefined` so a template referencing a field the caller did not supply fails
    loudly instead of rendering an empty string into a message someone receives.
    """
    if template is None:
        raise ValueError("template is required")
    if len(template) > _MAX_TEMPLATE_CHARS:
        raise TemplateTooLargeError(
            f"template is {len(template)} chars, over the {_MAX_TEMPLATE_CHARS} limit"
        )
    return _environment().from_string(template).render(**(data or {}))


def resolve_preferences(payload: dict | None) -> dict:
    """Merge a recipient's stated preferences over the defaults, ignoring keys that are not
    real preferences so an arbitrary payload cannot introduce new ones."""
    resolved = dict(DEFAULT_PREFERENCES)
    for key, value in (payload or {}).items():
        if key in DEFAULT_PREFERENCES:
            resolved[key] = value
    return resolved
