"use strict";

const _ = require("lodash");

/**
 * Renders a user-notification message from an admin-configured template and a
 * per-recipient data object. Templates are authored by service admins (stored
 * config, not end-user input); recipient data comes from the request body.
 */
function renderNotification(templateSource, data) {
  if (typeof templateSource !== "string" || !templateSource.length) {
    throw new TypeError("templateSource must be a non-empty string");
  }
  const compiled = _.template(templateSource);
  return compiled(data || {});
}

/**
 * Merges a per-recipient preferences object onto the service's default
 * notification preferences, without ever letting the caller override keys
 * outside the known preference set.
 */
const DEFAULT_PREFERENCES = Object.freeze({
  channel: "email",
  digest: false,
  locale: "en-US",
});

function resolvePreferences(overrides) {
  const allowed = _.pick(overrides || {}, Object.keys(DEFAULT_PREFERENCES));
  return _.defaults({}, allowed, DEFAULT_PREFERENCES);
}

module.exports = { renderNotification, resolvePreferences, DEFAULT_PREFERENCES };
