"use strict";

const express = require("express");
const { renderNotification, resolvePreferences } = require("./notification");

function createApp() {
  const app = express();
  app.use(express.json());

  app.get("/healthz", (_req, res) => {
    res.status(200).json({ status: "ok" });
  });

  app.post("/notifications/render", (req, res) => {
    const { template, data } = req.body || {};
    try {
      const rendered = renderNotification(template, data);
      res.status(200).json({ rendered });
    } catch (err) {
      res.status(400).json({ error: err.message });
    }
  });

  app.post("/notifications/preferences", (req, res) => {
    res.status(200).json({ preferences: resolvePreferences(req.body) });
  });

  return app;
}

module.exports = { createApp };

if (require.main === module) {
  const port = process.env.PORT || 3000;
  createApp().listen(port, () => {
    // eslint-disable-next-line no-console
    console.log(`orca-poc-target listening on :${port}`);
  });
}
