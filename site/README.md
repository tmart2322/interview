# Meridian Health — Demo Marketing Site

Fictional US health payer marketing page used as the "host surface" for the
Salesforce panel-interview demo. Not a real company, not affiliated with any
real insurer. Single static `index.html` (inline CSS + JS, no build step).

## Local preview

Open `index.html` directly in a browser, or serve the directory:

```bash
python3 -m http.server --directory site 8080
# then visit http://localhost:8080
```

## Auto-deploy to GitHub Pages

The workflow at `../.github/workflows/pages.yml` uploads only the `site/`
directory and deploys it to Pages on every push to `main` that touches
`site/**`. First-time setup:

1. Repo **Settings -> Pages -> Build and deployment -> Source: GitHub Actions**
2. Push to `main`. The workflow creates the `github-pages` environment and
   publishes to `https://<user>.github.io/<repo>/`.

## Agentforce Embedded Messaging

Paste the Salesforce-generated Embedded Messaging snippet immediately before
`</body>` — the exact location is marked in `index.html` with:

```html
<!-- AGENTFORCE_EMBEDDED_MESSAGING_SNIPPET -->
```

The on-page "Chat with us" button (`#chatBtn`) shows a placeholder
`Loading agent...` alert until the real snippet loads; once
`embeddedservice_bootstrap` / `embedded_svc` is present the placeholder
yields to the real widget.
