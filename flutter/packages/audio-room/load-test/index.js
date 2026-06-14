import WebSocket from 'ws';

// ─── Config ───────────────────────────────────────────────────────────────────
const APP_ID = '2886260444';
const SERVER_SECRET = 'd39e503fb23957e61dbbb4168e245673';
const STREAM_BASE_URL = 'https://udt-stream.com';

const ROOM_ID = process.argv[2] || '1';
const ROOM_OWNER_ID = process.argv[3] || '1';
const TOTAL_USERS = parseInt(process.argv[4] || '150', 10);
const BATCH_SIZE = parseInt(process.argv[5] || '10', 10);
const DELAY_BETWEEN_BATCHES_MS = 500;

// ─── State ────────────────────────────────────────────────────────────────────
const connections = [];
let connected = 0;
let failed = 0;
let tokenErrors = 0;

// ─── Token Generation ─────────────────────────────────────────────────────────
async function getToken(userId, userName) {
  const res = await fetch(`${STREAM_BASE_URL}/api/v1/token`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-App-Id': APP_ID,
      'X-App-Secret': SERVER_SECRET,
    },
    body: JSON.stringify({
      identity: String(userId),
      room_name: String(ROOM_ID),
      service: 'rooms',
      room_owner_id: String(ROOM_OWNER_ID),
      role: 'audience',
      name: userName,
    }),
  });

  if (!res.ok) {
    throw new Error(`Token API ${res.status}: ${await res.text()}`);
  }

  const data = await res.json();
  return { token: data.token, url: data.url };
}

// ─── WebSocket Connection ─────────────────────────────────────────────────────
function connectUser(token, wsUrl, userId) {
  return new Promise((resolve) => {
    const url = `${wsUrl.replace('https://', 'wss://').replace('http://', 'ws://')}/rtc?access_token=${encodeURIComponent(token)}&auto_subscribe=0&protocol=13`;

    const ws = new WebSocket(url);

    const timeout = setTimeout(() => {
      ws.terminate();
      failed++;
      resolve(null);
    }, 15000);

    ws.on('open', () => {
      clearTimeout(timeout);
      connected++;
      connections.push(ws);
      resolve(ws);
    });

    ws.on('error', () => {
      clearTimeout(timeout);
      failed++;
      resolve(null);
    });

    ws.on('close', () => {
      connected--;
    });
  });
}

// ─── Progress ─────────────────────────────────────────────────────────────────
function printProgress(batch, total) {
  const processed = Math.min(batch * BATCH_SIZE, total);
  const pct = ((processed / total) * 100).toFixed(1);
  process.stdout.write(
    `\r[${pct}%] Processed: ${processed}/${total} | Connected: ${connected} | Failed: ${failed} | Token errors: ${tokenErrors}   `
  );
}

// ─── Main ─────────────────────────────────────────────────────────────────────
async function main() {
  console.log(`\n=== Audio Room Load Test ===`);
  console.log(`Room: ${ROOM_ID} | Owner: ${ROOM_OWNER_ID}`);
  console.log(`Target: ${TOTAL_USERS} users | Batch: ${BATCH_SIZE}\n`);

  const startTime = Date.now();
  const totalBatches = Math.ceil(TOTAL_USERS / BATCH_SIZE);

  for (let batch = 0; batch < totalBatches; batch++) {
    const batchStart = batch * BATCH_SIZE;
    const batchEnd = Math.min(batchStart + BATCH_SIZE, TOTAL_USERS);

    const promises = [];

    for (let i = batchStart; i < batchEnd; i++) {
      const userId = 100000 + i;
      const userName = `LoadTest_User_${i + 1}`;

      promises.push(
        getToken(userId, userName)
          .then(({ token, url }) => connectUser(token, url, userId))
          .catch(() => {
            tokenErrors++;
            return null;
          })
      );
    }

    await Promise.all(promises);
    printProgress(batch + 1, TOTAL_USERS);

    if (batch < totalBatches - 1) {
      await new Promise((r) => setTimeout(r, DELAY_BETWEEN_BATCHES_MS));
    }
  }

  const elapsed = ((Date.now() - startTime) / 1000).toFixed(1);
  const memMB = (process.memoryUsage().heapUsed / 1024 / 1024).toFixed(1);

  console.log(`\n\n=== Results ===`);
  console.log(`Time: ${elapsed}s`);
  console.log(`Connected: ${connected}`);
  console.log(`Failed: ${failed}`);
  console.log(`Token errors: ${tokenErrors}`);
  console.log(`Memory: ${memMB} MB`);
  console.log(`\nPress Ctrl+C to disconnect all.\n`);

  process.on('SIGINT', () => {
    console.log(`\nDisconnecting ${connections.length} users...`);
    connections.forEach((ws) => ws.close());
    setTimeout(() => process.exit(0), 2000);
  });
}

main().catch(console.error);
