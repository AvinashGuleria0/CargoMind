const { spawn } = require('child_process');
const axios = require('axios');
const assert = require('assert');
const net = require('net');

const PORT = Number(process.env.TEST_PORT || 18080);
const BASE_URL = `http://127.0.0.1:${PORT}`;
const REQUIRE_FIRESTORE_WRITE =
  String(process.env.REQUIRE_FIRESTORE_WRITE || 'false').toLowerCase() === 'true';
const USE_EXISTING_SERVER =
  String(process.env.USE_EXISTING_SERVER || 'false').toLowerCase() === 'true';

let spawnedServer = null;

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function isServerUp() {
  try {
    const response = await axios.get(`${BASE_URL}/health`, { timeout: 1000 });
    return response.status === 200;
  } catch (_) {
    return false;
  }
}

function isPortInUse(port) {
  return new Promise((resolve) => {
    const socket = net.createConnection({ port, host: '127.0.0.1' });

    socket.once('connect', () => {
      socket.destroy();
      resolve(true);
    });

    socket.once('error', () => {
      resolve(false);
    });

    socket.setTimeout(600, () => {
      socket.destroy();
      resolve(false);
    });
  });
}

async function waitForServer(maxAttempts = 20) {
  for (let i = 0; i < maxAttempts; i += 1) {
    if (await isServerUp()) {
      return true;
    }
    await sleep(500);
  }
  return false;
}

function startServer() {
  spawnedServer = spawn('node', ['index.js'], {
    cwd: process.cwd(),
    env: {
      ...process.env,
      PORT: String(PORT),
    },
    stdio: 'inherit',
    shell: true,
  });

  spawnedServer.on('exit', (code, signal) => {
    if (signal === 'SIGTERM' || signal === 'SIGINT') {
      return;
    }

    if (code !== 0) {
      console.error(`Server exited with code ${code}`);
    }
  });
}

async function run() {
  if (USE_EXISTING_SERVER) {
    const serverAlreadyRunning = await isServerUp();
    assert(
      serverAlreadyRunning,
      `No server detected at ${BASE_URL}. Start it first or unset USE_EXISTING_SERVER.`
    );
  } else {
    const serverAlreadyRunning = await isServerUp();

    if (serverAlreadyRunning) {
      console.log(`Using existing server at ${BASE_URL}`);
    } else {
      const busyPort = await isPortInUse(PORT);
      assert(
        !busyPort,
        `Port ${PORT} is in use by another process. Stop it or run with TEST_PORT=<free-port>.`
      );

      startServer();
      const started = await waitForServer();
      assert(started, 'Server did not become healthy in time.');
    }
  }

  const payload = {
    vehicle_id: 'MH-12',
    incident_type: 'ROAD_BLOCK',
    severity: 'MEDIUM',
    current_lat: 28.6139,
    current_lng: 77.2090,
    temperature_celsius: 6.2,
    estimated_value_inr: 210000,
  };

  const response = await axios.post(`${BASE_URL}/api/trigger-incident`, payload, {
    timeout: 30000,
  });

  assert.strictEqual(response.status, 200, 'Expected HTTP 200 from incident route.');
  assert.strictEqual(
    response.data?.message,
    'Incident triage completed',
    'Expected success message from route.'
  );

  const result = response.data?.result;
  assert(result, 'Route did not return result payload.');
  assert(result.decision, 'Missing decision object in response.');
  assert(result.decision.new_target_location, 'Missing new_target_location in decision.');
  assert(result.decision.justification_log, 'Missing justification_log in decision.');
  assert(result.geocode, 'Missing geocode info in response.');
  assert(result.routePlan, 'Missing routePlan in response.');
  assert(result.firestoreWrite, 'Missing firestoreWrite in response.');

  if (REQUIRE_FIRESTORE_WRITE) {
    assert.strictEqual(
      result.firestoreWrite.written,
      true,
      'Expected Firestore write to be true when REQUIRE_FIRESTORE_WRITE=true.'
    );
  }

  console.log('Integration test passed.');
  console.log(
    JSON.stringify(
      {
        decision: result.decision,
        geocode_source: result.geocode.source,
        route_source: result.routePlan.source,
        firestore_write: result.firestoreWrite,
      },
      null,
      2
    )
  );
}

run()
  .catch((error) => {
    console.error('Integration test failed:');
    console.error(error.message || error);
    process.exitCode = 1;
  })
  .finally(() => {
    if (spawnedServer && !spawnedServer.killed) {
      spawnedServer.kill('SIGTERM');
    }
  });
