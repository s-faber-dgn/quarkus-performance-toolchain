import http from 'k6/http';
import { check, sleep } from 'k6';

const baseUrl = __ENV.K6_BASE_URL || 'http://localhost:8080';
const path = __ENV.K6_PATH;

if (!path || !path.startsWith('/') || path.startsWith('/q/')) {
  throw new Error('K6_PATH muss ein echter, nicht destruktiver App-Endpunkt sein (z. B. /api/items), kein /q/-Endpunkt.');
}

export const options = {
  vus: Number(__ENV.K6_VUS || 5),
  duration: __ENV.K6_DURATION || '1m',
  thresholds: {
    http_req_failed: ['rate<0.01'],
    http_req_duration: ['p(95)<500'],
  },
};

export default function () {
  const response = http.get(`${baseUrl}${path}`);
  check(response, { 'status is 2xx': (r) => r.status >= 200 && r.status < 300 });
  sleep(0.2);
}

