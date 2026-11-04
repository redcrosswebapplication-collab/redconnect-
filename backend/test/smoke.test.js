'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const { spawn, spawnSync } = require('node:child_process');
const { once } = require('node:events');
const net = require('node:net');
const path = require('node:path');

test('API fails fast when Supabase server credentials are missing', () => {
  const result = spawnSync(process.execPath, ['src/server.js'], {
    cwd: path.join(__dirname, '..'),
    env: {
      ...process.env,
      SUPABASE_URL: '',
      SUPABASE_PUBLISHABLE_KEY: '',
      SUPABASE_ANON_KEY: '',
      SUPABASE_SERVICE_ROLE_KEY: '',
    },
    encoding: 'utf8',
  });
  assert.notEqual(result.status, 0);
  assert.match(result.stderr, /Set SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY, and SUPABASE_SERVICE_ROLE_KEY/);
});

test('API boots with Supabase config and protects authenticated routes', async () => {
  const listener = net.createServer();
  await new Promise((resolve) => listener.listen(0, '127.0.0.1', resolve));
  const port = listener.address().port;
  await new Promise((resolve) => listener.close(resolve));
  const server = spawn(process.execPath, ['src/server.js'], {
    cwd: path.join(__dirname, '..'),
    env: {
      ...process.env,
      PORT: String(port),
      SUPABASE_URL: 'https://example.supabase.co',
      SUPABASE_PUBLISHABLE_KEY: 'test-publishable-key',
      SUPABASE_ANON_KEY: '',
      SUPABASE_SERVICE_ROLE_KEY: 'test-service-role-key',
    },
    stdio: 'ignore',
  });
  try {
    let response;
    for (let attempt = 0; attempt < 30; attempt++) {
      try {
        response = await fetch(`http://127.0.0.1:${port}/health`);
        break;
      } catch {
        await new Promise((resolve) => setTimeout(resolve, 50));
      }
    }
    assert.equal(response?.status, 200);
    const protectedResponse = await fetch(`http://127.0.0.1:${port}/api/me`);
    assert.equal(protectedResponse.status, 401);
  } finally {
    server.kill();
    await once(server, 'exit');
  }
});