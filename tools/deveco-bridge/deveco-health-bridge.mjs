import { spawn } from 'node:child_process';
import { randomBytes, randomUUID } from 'node:crypto';
import { existsSync } from 'node:fs';
import http from 'node:http';
import os from 'node:os';
import path from 'node:path';
import process from 'node:process';
import { fileURLToPath } from 'node:url';

const BRIDGE_HOST = '127.0.0.1';
const BRIDGE_PORT = readPort(process.env.HEALTHLIFE_BRIDGE_PORT, 8787);
const DEVECO_PORT = readPort(process.env.HEALTHLIFE_DEVECO_PORT, 8788);
const DEVECO_HOST = '127.0.0.1';
const DEVECO_URL = `http://${DEVECO_HOST}:${DEVECO_PORT}`;
const MODEL = { providerID: 'deveco', modelID: 'GLM-5.1' };
const SESSION_MODEL = { providerID: 'deveco', id: 'GLM-5.1' };
const MAX_BODY_BYTES = 32 * 1024;
const MAX_MESSAGE_LENGTH = 4000;
const REQUEST_TIMEOUT_MS = 180_000;
const SESSION_TTL_MS = 30 * 60 * 1000;
const STARTUP_TIMEOUT_MS = 30_000;
const RUNTIME_DIR = path.dirname(fileURLToPath(import.meta.url));
const DEVECO_LOG_LEVEL = ['DEBUG', 'INFO', 'WARN', 'ERROR'].includes(process.env.HEALTHLIFE_DEVECO_LOG_LEVEL)
  ? process.env.HEALTHLIFE_DEVECO_LOG_LEVEL
  : 'ERROR';
const DEBUG_LOGS = process.env.HEALTHLIFE_DEBUG === '1';

const devecoPassword = randomBytes(24).toString('hex');
const devecoAuth = `Basic ${Buffer.from(`deveco:${devecoPassword}`, 'utf8').toString('base64')}`;
const conversations = new Map();
let devecoProcess;
let shuttingDown = false;

class HttpError extends Error {
  constructor(status, message) {
    super(message);
    this.status = status;
  }
}

function readPort(raw, fallback) {
  const value = Number(raw ?? fallback);
  if (!Number.isInteger(value) || value < 1 || value > 65535) {
    throw new Error(`非法端口: ${raw}`);
  }
  return value;
}

function sanitizeLog(value) {
  return String(value)
    .replace(/sk-[A-Za-z0-9_-]{12,}/g, '[REDACTED_KEY]')
    .replace(/Bearer\s+[^\s]+/gi, 'Bearer [REDACTED]')
    .slice(-4000);
}

function resolveDevecoLaunch() {
  const explicitEntry = process.env.DEVECO_ENTRY;
  if (explicitEntry && existsSync(explicitEntry)) {
    return { command: process.execPath, prefix: [explicitEntry], shell: false };
  }

  if (process.platform === 'win32' && process.env.APPDATA) {
    const npmEntry = path.join(
      process.env.APPDATA,
      'npm',
      'node_modules',
      '@deveco',
      'deveco-code',
      'bin',
      'deveco'
    );
    if (existsSync(npmEntry)) {
      return { command: process.execPath, prefix: [npmEntry], shell: false };
    }
  }

  return {
    command: process.platform === 'win32' ? 'deveco.cmd' : 'deveco',
    prefix: [],
    shell: process.platform === 'win32'
  };
}

async function devecoFetch(endpoint, options = {}, timeoutMs = REQUEST_TIMEOUT_MS) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  try {
    const response = await fetch(`${DEVECO_URL}${endpoint}`, {
      ...options,
      headers: {
        Authorization: devecoAuth,
        'Content-Type': 'application/json',
        ...(options.headers ?? {})
      },
      signal: controller.signal
    });
    const text = await response.text();
    let payload = null;
    if (text.length > 0) {
      try {
        payload = JSON.parse(text);
      } catch {
        payload = text;
      }
    }
    if (!response.ok) {
      const detail = typeof payload === 'string'
        ? payload
        : payload?.data?.message ?? payload?.message ?? `HTTP ${response.status}`;
      throw new HttpError(response.status, `DevEco 请求失败: ${detail}`);
    }
    return payload;
  } catch (error) {
    if (error?.name === 'AbortError') {
      throw new HttpError(504, 'GLM-5.1 回复超时，请稍后重试');
    }
    throw error;
  } finally {
    clearTimeout(timer);
  }
}

async function waitForDeveco() {
  const startedAt = Date.now();
  while (Date.now() - startedAt < STARTUP_TIMEOUT_MS) {
    if (devecoProcess?.exitCode !== null) {
      throw new Error('DevEco 服务启动后立即退出');
    }
    try {
      const health = await devecoFetch('/global/health', { method: 'GET' }, 1000);
      if (health?.healthy === true) {
        return;
      }
    } catch {
      // The service needs a few seconds to load its runtime and provider config.
    }
    await new Promise((resolve) => setTimeout(resolve, 400));
  }
  throw new Error(`DevEco 服务在 ${STARTUP_TIMEOUT_MS / 1000} 秒内未就绪`);
}

async function startDeveco() {
  const launch = resolveDevecoLaunch();
  const childEnv = { ...process.env };
  // The bridge only uses the DevEco OAuth provider. Do not expose unrelated
  // provider keys through DevEco's broad configuration API.
  delete childEnv.OPENAI_API_KEY;
  delete childEnv.ANTHROPIC_API_KEY;
  delete childEnv.GEMINI_API_KEY;
  childEnv.DEVECO_SERVER_USERNAME = 'deveco';
  childEnv.DEVECO_SERVER_PASSWORD = devecoPassword;

  const args = [
    ...launch.prefix,
    'serve',
    '--hostname',
    DEVECO_HOST,
    '--port',
    String(DEVECO_PORT),
    '--pure',
    '--log-level',
    DEVECO_LOG_LEVEL
  ];
  devecoProcess = spawn(launch.command, args, {
    cwd: RUNTIME_DIR,
    env: childEnv,
    shell: launch.shell,
    windowsHide: true,
    stdio: ['ignore', 'pipe', 'pipe']
  });

  let startupOutput = '';
  const collectOutput = (chunk) => {
    startupOutput = sanitizeLog(startupOutput + chunk.toString('utf8'));
    if (DEBUG_LOGS) {
      process.stderr.write(sanitizeLog(chunk.toString('utf8')));
    }
  };
  devecoProcess.stdout.on('data', collectOutput);
  devecoProcess.stderr.on('data', collectOutput);
  devecoProcess.on('error', (error) => {
    console.error(`[bridge] 无法启动 deveco: ${error.message}`);
  });
  devecoProcess.on('exit', (code) => {
    if (!shuttingDown) {
      console.error(`[bridge] DevEco 服务意外退出 (${code ?? 'unknown'}): ${startupOutput}`);
    }
  });

  try {
    await waitForDeveco();
  } catch (error) {
    if (startupOutput.length > 0) {
      console.error(`[bridge] DevEco 启动输出: ${startupOutput}`);
    }
    throw error;
  }
}

async function createSession() {
  const session = await devecoFetch('/session', {
    method: 'POST',
    body: JSON.stringify({
      title: 'HealthLife AI 诊断对话',
      agent: 'healthlife',
      model: SESSION_MODEL,
      permission: [
        { permission: '*', pattern: '*', action: 'deny' }
      ],
      metadata: { source: 'healthlife-bridge' }
    })
  });
  if (!session?.id) {
    throw new HttpError(502, 'DevEco 未返回会话编号');
  }
  return session.id;
}

async function getConversation(requestedID) {
  if (requestedID && conversations.has(requestedID)) {
    return { id: requestedID, state: conversations.get(requestedID) };
  }

  const id = randomUUID();
  const state = {
    sessionID: await createSession(),
    lastUsed: Date.now(),
    busy: false
  };
  conversations.set(id, state);
  return { id, state };
}

function extractReply(payload) {
  const parts = Array.isArray(payload?.parts) ? payload.parts : [];
  const reply = parts
    .filter((part) => part?.type === 'text' && typeof part.text === 'string' && part.text.trim().length > 0)
    .map((part) => part.text.trim())
    .join('\n')
    .trim();
  if (reply.length === 0) {
    throw new HttpError(502, 'GLM-5.1 返回了空回复');
  }
  return reply;
}

async function sendChat(message, requestedConversationID) {
  const startedAt = Date.now();
  const conversation = await getConversation(requestedConversationID);
  if (conversation.state.busy) {
    throw new HttpError(409, '当前对话仍在生成回复，请稍候');
  }
  conversation.state.busy = true;
  conversation.state.lastUsed = Date.now();
  console.log(`[bridge] Chat started (conversation=${conversation.id}, session=${conversation.state.sessionID})`);
  try {
    const payload = await devecoFetch(`/session/${conversation.state.sessionID}/message`, {
      method: 'POST',
      body: JSON.stringify({
        model: MODEL,
        agent: 'healthlife',
        tools: { '*': false },
        format: { type: 'text' },
        parts: [{ type: 'text', text: message }]
      })
    });
    conversation.state.lastUsed = Date.now();
    console.log(`[bridge] Chat completed in ${Date.now() - startedAt} ms (conversation=${conversation.id})`);
    return {
      conversationId: conversation.id,
      reply: extractReply(payload)
    };
  } finally {
    conversation.state.busy = false;
  }
}

async function readJsonBody(request) {
  const chunks = [];
  let size = 0;
  for await (const chunk of request) {
    size += chunk.length;
    if (size > MAX_BODY_BYTES) {
      throw new HttpError(413, '请求内容过长');
    }
    chunks.push(chunk);
  }
  if (chunks.length === 0) {
    throw new HttpError(400, '请求体不能为空');
  }
  try {
    return JSON.parse(Buffer.concat(chunks).toString('utf8'));
  } catch {
    throw new HttpError(400, '请求体不是合法 JSON');
  }
}

function writeJson(response, status, payload) {
  const body = JSON.stringify(payload);
  response.writeHead(status, {
    'Content-Type': 'application/json; charset=utf-8',
    'Content-Length': Buffer.byteLength(body),
    'Cache-Control': 'no-store'
  });
  response.end(body);
}

const bridgeServer = http.createServer(async (request, response) => {
  try {
    if (request.method === 'GET' && request.url === '/health') {
      const health = await devecoFetch('/global/health', { method: 'GET' }, 2000);
      writeJson(response, 200, {
        healthy: health?.healthy === true,
        model: 'deveco/GLM-5.1',
        bridgeVersion: 1
      });
      return;
    }

    if (request.method === 'POST' && request.url === '/chat') {
      const body = await readJsonBody(request);
      const message = typeof body?.message === 'string' ? body.message.trim() : '';
      const conversationId = typeof body?.conversationId === 'string'
        ? body.conversationId.trim()
        : '';
      if (message.length === 0) {
        throw new HttpError(400, '请输入要咨询的内容');
      }
      if (message.length > MAX_MESSAGE_LENGTH) {
        throw new HttpError(400, `单次输入不能超过 ${MAX_MESSAGE_LENGTH} 个字符`);
      }
      if (conversationId.length > 0 && !/^[0-9a-f-]{36}$/i.test(conversationId)) {
        throw new HttpError(400, '对话编号格式错误');
      }
      writeJson(response, 200, await sendChat(message, conversationId));
      return;
    }

    throw new HttpError(404, '接口不存在');
  } catch (error) {
    const status = Number.isInteger(error?.status) ? error.status : 500;
    const message = status >= 500
      ? (error?.message || '桥接服务暂时不可用')
      : error.message;
    console.error(`[bridge] ${request.method} ${request.url}: ${sanitizeLog(message)}`);
    if (!response.headersSent) {
      writeJson(response, status, { error: message });
    } else {
      response.end();
    }
  }
});

async function deleteSession(sessionID) {
  try {
    await devecoFetch(`/session/${sessionID}`, { method: 'DELETE' }, 5000);
  } catch (error) {
    console.error(`[bridge] 清理会话失败: ${sanitizeLog(error.message)}`);
  }
}

async function cleanupExpiredSessions() {
  const cutoff = Date.now() - SESSION_TTL_MS;
  for (const [id, state] of conversations.entries()) {
    if (!state.busy && state.lastUsed < cutoff) {
      conversations.delete(id);
      await deleteSession(state.sessionID);
    }
  }
}

const cleanupTimer = setInterval(() => {
  void cleanupExpiredSessions();
}, 60_000);
cleanupTimer.unref();

async function shutdown(exitCode = 0) {
  if (shuttingDown) {
    return;
  }
  shuttingDown = true;
  clearInterval(cleanupTimer);
  bridgeServer.close();
  for (const state of conversations.values()) {
    await deleteSession(state.sessionID);
  }
  conversations.clear();
  if (devecoProcess && devecoProcess.exitCode === null) {
    devecoProcess.kill();
  }
  process.exit(exitCode);
}

process.on('SIGINT', () => void shutdown(0));
process.on('SIGTERM', () => void shutdown(0));

try {
  await startDeveco();
  bridgeServer.listen(BRIDGE_PORT, BRIDGE_HOST, () => {
    console.log(`[bridge] HealthLife AI bridge ready: http://${BRIDGE_HOST}:${BRIDGE_PORT}`);
    console.log(`[bridge] Model: deveco/GLM-5.1; sessions expire after ${SESSION_TTL_MS / 60_000} minutes`);
  });
} catch (error) {
  console.error(`[bridge] 启动失败: ${sanitizeLog(error.message)}`);
  await shutdown(1);
}
