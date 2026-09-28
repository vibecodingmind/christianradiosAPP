import http from 'node:http';
import https from 'node:https';
import { URL } from 'node:url';

const PORT = Number(process.env.PROXY_PORT || 3031);
const TARGET_ORIGIN = 'https://christianradios-production.up.railway.app';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS, PATCH',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Requested-With, Range',
  'Access-Control-Expose-Headers': 'Content-Length, Content-Range, Content-Type',
};

const server = http.createServer(async (req, res) => {
  if (req.method === 'OPTIONS') {
    res.writeHead(204, corsHeaders);
    res.end();
    return;
  }

  try {
    const reqUrl = new URL(req.url || '/', `http://localhost:${PORT}`);

    // Image CORS proxy for Flutter Web CanvasKit third-party station logos
    if (reqUrl.pathname === '/img') {
      const rawImgUrl = reqUrl.searchParams.get('url');
      if (!rawImgUrl) {
        res.writeHead(400, corsHeaders);
        res.end('Missing url');
        return;
      }
      const controller = new AbortController();
      const timeout = setTimeout(() => controller.abort(), 6000);
      try {
        const imgResp = await fetch(rawImgUrl, {
          signal: controller.signal,
          headers: {
            'User-Agent': 'Mozilla/5.0 (compatible; ChristianRadios/1.0)',
            Accept: 'image/*,*/*;q=0.8',
          },
        });
        clearTimeout(timeout);
        if (!imgResp.ok) {
          res.writeHead(imgResp.status, corsHeaders);
          res.end();
          return;
        }
        const contentType = imgResp.headers.get('content-type') || 'image/png';
        const buf = Buffer.from(await imgResp.arrayBuffer());
        res.writeHead(200, {
          ...corsHeaders,
          'Content-Type': contentType,
          'Cache-Control': 'public, max-age=86400',
        });
        res.end(buf);
      } catch {
        clearTimeout(timeout);
        res.writeHead(404, corsHeaders);
        res.end();
      }
      return;
    }

    // Forward /api/* to Railway production API with Origin: http://localhost:3000
    const targetUrl = new URL(req.url || '/', TARGET_ORIGIN);
    const bodyChunks = [];
    for await (const chunk of req) {
      bodyChunks.push(chunk);
    }
    const bodyBuffer = bodyChunks.length > 0 ? Buffer.concat(bodyChunks) : undefined;

    const forwardHeaders = {
      Origin: 'http://localhost:3000',
      Accept: req.headers['accept'] || 'application/json',
    };
    if (req.headers['content-type']) {
      forwardHeaders['Content-Type'] = req.headers['content-type'];
    }
    if (req.headers['authorization']) {
      forwardHeaders['Authorization'] = req.headers['authorization'];
    }

    const upstreamResp = await fetch(targetUrl.toString(), {
      method: req.method || 'GET',
      headers: forwardHeaders,
      body: req.method !== 'GET' && req.method !== 'HEAD' ? bodyBuffer : undefined,
    });

    const contentType = upstreamResp.headers.get('content-type') || 'application/json';
    let payload = Buffer.from(await upstreamResp.arrayBuffer());

    // Rewrite third-party station logoUrls so Flutter Web CanvasKit doesn't fail on image CORS
    if (contentType.includes('application/json')) {
      try {
        const text = payload.toString('utf8');
        const rewritten = text.replace(
          /"logoUrl"\s*:\s*"(https?:\/\/[^"]+)"/g,
          (match, url) => {
            if (url.includes('images.unsplash.com') || url.includes('localhost:3031')) {
              return match;
            }
            return `"logoUrl":"http://localhost:${PORT}/img?url=${encodeURIComponent(url)}"`;
          },
        );
        payload = Buffer.from(rewritten, 'utf8');
      } catch {
        // Keep original payload if JSON rewrite fails
      }
    }

    res.writeHead(upstreamResp.status, {
      ...corsHeaders,
      'Content-Type': contentType,
    });
    res.end(payload);
  } catch (err) {
    res.writeHead(502, {
      ...corsHeaders,
      'Content-Type': 'application/json',
    });
    res.end(JSON.stringify({ error: 'Proxy request failed', details: String(err) }));
  }
});

server.listen(PORT, '127.0.0.1', () => {
  console.log(`CORS Relay Proxy listening on http://localhost:${PORT} -> ${TARGET_ORIGIN}`);
});
