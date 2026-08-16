"use strict";

const request = require("supertest");
const { createApp } = require("../src/server");

describe("GET /healthz", () => {
  it("returns 200 ok", async () => {
    const res = await request(createApp()).get("/healthz");
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ status: "ok" });
  });
});

describe("POST /notifications/render", () => {
  it("renders a template with the given data", async () => {
    const res = await request(createApp())
      .post("/notifications/render")
      .send({ template: "Hi <%= name %>!", data: { name: "Ada" } });
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ rendered: "Hi Ada!" });
  });

  it("returns 400 on a missing template", async () => {
    const res = await request(createApp()).post("/notifications/render").send({});
    expect(res.status).toBe(400);
  });
});

describe("POST /notifications/preferences", () => {
  it("returns resolved preferences", async () => {
    const res = await request(createApp())
      .post("/notifications/preferences")
      .send({ channel: "sms" });
    expect(res.status).toBe(200);
    expect(res.body.preferences.channel).toBe("sms");
  });
});
