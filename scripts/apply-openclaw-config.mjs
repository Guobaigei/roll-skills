#!/usr/bin/env node

import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const skillDir = path.resolve(scriptDir, "..");

function parseArgs(argv) {
  const args = {};
  for (let i = 0; i < argv.length; i += 1) {
    const part = argv[i];
    if (part === "--env-file") {
      args.envFile = argv[i + 1];
      i += 1;
    }
  }
  return args;
}

function parseEnvFile(filePath) {
  const raw = fs.readFileSync(filePath, "utf8");
  const entries = {};

  for (const line of raw.split(/\r?\n/)) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith("#")) {
      continue;
    }

    const eqIndex = trimmed.indexOf("=");
    if (eqIndex === -1) {
      continue;
    }

    const key = trimmed.slice(0, eqIndex).trim();
    let value = trimmed.slice(eqIndex + 1).trim();

    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1);
    }

    entries[key] = value;
  }

  return entries;
}

function writeMergedEnv(targetPath, nextVars) {
  const existing = fs.existsSync(targetPath) ? parseEnvFile(targetPath) : {};
  const merged = { ...existing, ...nextVars };
  const lines = Object.entries(merged)
    .sort(([a], [b]) => a.localeCompare(b))
    .map(([key, value]) => `${key}=${value}`);
  fs.mkdirSync(path.dirname(targetPath), { recursive: true });
  fs.writeFileSync(targetPath, `${lines.join("\n")}\n`, "utf8");
}

function run(command, args, env) {
  const result = spawnSync(command, args, {
    stdio: "inherit",
    env,
  });

  if (result.error) {
    throw result.error;
  }

  if (result.status !== 0) {
    throw new Error(`${command} ${args.join(" ")} failed with exit code ${result.status}`);
  }
}

function configSet(pathName, value, env) {
  run("openclaw", ["config", "set", pathName, value], env);
}

function ensureRequired(envVars) {
  const hasQwen =
    Boolean(envVars.QWEN_API_KEY) ||
    Boolean(envVars.MODELSTUDIO_API_KEY) ||
    Boolean(envVars.DASHSCOPE_API_KEY);

  const missing = [];
  if (!hasQwen) {
    missing.push("QWEN_API_KEY or MODELSTUDIO_API_KEY or DASHSCOPE_API_KEY");
  }
  if (!envVars.DEEPSEEK_API_KEY) {
    missing.push("DEEPSEEK_API_KEY");
  }
  if (!envVars.FEISHU_APP_ID) {
    missing.push("FEISHU_APP_ID");
  }
  if (!envVars.FEISHU_APP_SECRET) {
    missing.push("FEISHU_APP_SECRET");
  }

  if (missing.length > 0) {
    throw new Error(`missing required env values: ${missing.join(", ")}`);
  }
}

const args = parseArgs(process.argv.slice(2));
const envFile =
  args.envFile ||
  path.join(skillDir, ".env");

if (!fs.existsSync(envFile)) {
  throw new Error(`env file not found: ${envFile}`);
}

const envFromFile = parseEnvFile(envFile);
ensureRequired(envFromFile);

const runtimeEnv = {
  ...process.env,
  ...envFromFile,
};

const openclawEnvFile = path.join(os.homedir(), ".openclaw", ".env");
writeMergedEnv(openclawEnvFile, envFromFile);

const botName = envFromFile.FEISHU_BOT_NAME || "OpenClaw";
const domain = envFromFile.FEISHU_DOMAIN || "feishu";

configSet("channels.feishu.enabled", "true", runtimeEnv);
configSet("channels.feishu.connectionMode", JSON.stringify("websocket"), runtimeEnv);
configSet("channels.feishu.dmPolicy", JSON.stringify("pairing"), runtimeEnv);
configSet("channels.feishu.defaultAccount", JSON.stringify("main"), runtimeEnv);
configSet("channels.feishu.accounts.main.appId", JSON.stringify("${FEISHU_APP_ID}"), runtimeEnv);
configSet(
  "channels.feishu.accounts.main.appSecret",
  JSON.stringify("${FEISHU_APP_SECRET}"),
  runtimeEnv,
);
configSet("channels.feishu.accounts.main.name", JSON.stringify(botName), runtimeEnv);

if (domain === "lark") {
  configSet("channels.feishu.domain", JSON.stringify("lark"), runtimeEnv);
}

run("openclaw", ["models", "set", "qwen/qwen3.6-plus"], runtimeEnv);
run("openclaw", ["models", "fallbacks", "clear"], runtimeEnv);
run("openclaw", ["models", "fallbacks", "add", "deepseek/deepseek-reasoner"], runtimeEnv);
run("openclaw", ["config", "validate"], runtimeEnv);

console.log(`Applied OpenClaw config from ${envFile}`);
console.log(`Synced runtime env to ${openclawEnvFile}`);
console.log("Primary model: qwen/qwen3.6-plus");
console.log("Fallback model: deepseek/deepseek-reasoner");
