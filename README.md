# orca-poc-target

Demo target service for the [Orca Security closed-loop remediation POC](https://github.com/junninho-orca/ai-remediation-demo).
A small Express service with a real, currently-vulnerable dependency
(`lodash@4.17.15`, prototype-pollution / template-injection issues fixed in
`4.17.21`) that the POC's remediation agents fix, test, and merge.

## What's here

- `src/notification.js` — renders admin-authored notification templates with
  recipient data via `lodash`'s `_.template`, and resolves per-recipient
  notification preferences via `_.pick`/`_.defaults`. This is the module the
  vulnerable dependency actually affects.
- `src/server.js` — a minimal Express API exposing that logic over HTTP.
- `tests/` — Jest test suite with full coverage on `notification.js`.
- `Dockerfile` — builds the service on `node:18-slim`.

## Development

```bash
npm install
npm test
npm start
```
