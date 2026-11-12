# Outage Page

When the server is off, Cloudflare shows `Error 1033 · Cloudflare Tunnel error`. The `hadeda-down` Cloudflare Worker replaces that with the "EISH. A flock of hadedas…" page.

This lives in the Cloudflare dashboard, not in Argo. [outage-page/worker.js](outage-page/worker.js) is a reference copy of what is deployed (page and image are embedded in it).

## How it works

- Routes `erasmus.works/*` and `*.erasmus.works/*` (zone `erasmus.works`, failure mode **Fail open**) send traffic through the Worker.
- The Worker passes every request to the origin. Only when the origin answers `>= 520` (tunnel down returns `530`) does it serve the page, as `503` with `Retry-After`.
- So it is harmless while the server is up, but every request still counts toward the free 100k/day Worker limit. Fail open means hitting the limit just skips the Worker.

## Turn on / off

Dashboard → Workers & Pages → `hadeda-down` → **Domains**:

- On: **Add Route** → zone `erasmus.works`, route `erasmus.works/*`, Fail open. Repeat for `*.erasmus.works/*`.
- Off (server is back): delete both routes. Keep the Worker for next time.

Other zones (e.g. `erasmuscloud.com`) are not covered unless you add routes for them.

## Update the page

1. Edit [outage-page/worker.js](outage-page/worker.js). The page HTML is the `PAGE` string; the images are WebP data URIs inside it. Landscape screens get the full image; portrait (phones) gets two crops of it stacked, "EISH." text on top and the birds below.
2. Dashboard → `hadeda-down` → **Edit code** → click in the editor, `Ctrl+A`, paste the file.
3. Click **Deploy**. A dot next to the Worker name means unsaved changes — pasting alone does not go live.

Small text changes can be done in place with the editor's find/replace (`Ctrl+H`) and then **Deploy**.

## Check

```bash
curl -s -o /dev/null -w '%{http_code}\n' https://erasmus.works/   # 503 = hadeda page, 530 = no Worker route
curl -s https://erasmus.works/ | grep -o 'flock of hadedas'
```

Testing on `hadeda-down.<account>.workers.dev` shows "Page not found" — the Worker fetches itself there. Test on the real domain.
