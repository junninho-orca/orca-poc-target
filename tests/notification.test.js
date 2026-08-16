"use strict";

const { renderNotification, resolvePreferences, DEFAULT_PREFERENCES } = require("../src/notification");

describe("renderNotification", () => {
  it("interpolates recipient data into an admin-authored template", () => {
    const result = renderNotification("Hi <%= name %>, you have <%= count %> new alerts.", {
      name: "Ada",
      count: 3,
    });
    expect(result).toBe("Hi Ada, you have 3 new alerts.");
  });

  it("throws when the template references data the caller never supplied", () => {
    // lodash's `_.template` compiles interpolation tokens as direct variable
    // references (via `with`), so a missing key is a ReferenceError, not a silent
    // blank — callers must supply every token the template uses.
    expect(() => renderNotification("Hello <%= name %>!", {})).toThrow(ReferenceError);
  });

  it("supports conditional template logic", () => {
    const template = "<% if (urgent) { %>URGENT: <% } %><%= subject %>";
    expect(renderNotification(template, { urgent: true, subject: "Server down" })).toBe(
      "URGENT: Server down"
    );
    expect(renderNotification(template, { urgent: false, subject: "Weekly digest" })).toBe(
      "Weekly digest"
    );
  });

  it("rejects a non-string template", () => {
    expect(() => renderNotification(42, {})).toThrow(TypeError);
  });

  it("rejects an empty template", () => {
    expect(() => renderNotification("", {})).toThrow(TypeError);
  });

  it("does not throw on a template with no interpolation tokens", () => {
    expect(renderNotification("Static message, no tokens here.", { unused: true })).toBe(
      "Static message, no tokens here."
    );
  });
});

describe("resolvePreferences", () => {
  it("returns the defaults when no overrides are given", () => {
    expect(resolvePreferences(undefined)).toEqual(DEFAULT_PREFERENCES);
    expect(resolvePreferences({})).toEqual(DEFAULT_PREFERENCES);
  });

  it("applies an allowed override on top of the defaults", () => {
    expect(resolvePreferences({ channel: "sms" })).toEqual({
      channel: "sms",
      digest: false,
      locale: "en-US",
    });
  });

  it("applies multiple allowed overrides at once", () => {
    expect(resolvePreferences({ channel: "sms", digest: true })).toEqual({
      channel: "sms",
      digest: true,
      locale: "en-US",
    });
  });

  it("ignores keys outside the known preference set", () => {
    const result = resolvePreferences({ channel: "sms", admin: true, __proto__: { polluted: true } });
    expect(result).toEqual({ channel: "sms", digest: false, locale: "en-US" });
    expect(result.polluted).toBeUndefined();
    expect({}.polluted).toBeUndefined();
  });
});
