import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { spawn } from "node:child_process";
import { homedir } from "node:os";
import { isAbsolute, join, resolve } from "node:path";

function shellQuote(value: string): string {
  return `'${value.replace(/'/g, `'\\''`)}'`;
}

function run(cmd: string, args: string[], cwd: string): Promise<{ code: number | null; out: string; err: string }> {
  return new Promise((resolveResult, reject) => {
    const child = spawn(cmd, args, { cwd, env: process.env });
    let out = "";
    let err = "";
    child.stdout?.setEncoding("utf8");
    child.stderr?.setEncoding("utf8");
    child.stdout?.on("data", (chunk) => { out += chunk; });
    child.stderr?.on("data", (chunk) => { err += chunk; });
    child.on("error", reject);
    child.on("close", (code) => resolveResult({ code, out, err }));
  });
}

async function copyToClipboard(text: string) {
  const child = spawn("pbcopy");
  child.stdin.end(text);
  await new Promise((resolve) => child.on("close", resolve));
}

async function openWarpNvim(cwd: string, file: string) {
  const command = `cd ${shellQuote(cwd)} && nvim ${shellQuote(file)}`;
  const url = `warp://action/new_tab?path=${encodeURIComponent(cwd)}&command=${encodeURIComponent(command)}`;
  return run("open", [url], cwd);
}

function resolveFile(cwd: string, arg: string): string {
  const trimmed = arg.trim();
  if (!trimmed) throw new Error("Missing file path");
  return isAbsolute(trimmed) ? trimmed : resolve(cwd, trimmed);
}

export default function openInNvim(pi: ExtensionAPI) {
  pi.registerCommand("nvim", {
    description: "Open a file in Neovim in a new Warp tab; copies the command as a fallback.",
    handler: async (args, ctx) => {
      let file: string;
      try {
        file = resolveFile(ctx.cwd, args);
      } catch (error) {
        ctx.ui.notify("Usage: /nvim <path>", "warning");
        return;
      }

      const command = `cd ${shellQuote(ctx.cwd)} && nvim ${shellQuote(file)}`;
      await copyToClipboard(command).catch(() => undefined);
      const result = await openWarpNvim(ctx.cwd, file).catch((e) => ({ code: 1, out: "", err: String(e) }));
      if (result.code === 0) {
        ctx.ui.notify(`Opened in Warp/nvim. Command copied too: ${file}`, "info");
      } else {
        ctx.ui.notify(`Could not open Warp. Copied command: ${command}`, "warning");
      }
    },
  });

  pi.registerCommand("nvim-zsh", {
    description: "Open ~/.zshrc in Neovim.",
    handler: async (_args, ctx) => {
      const file = join(homedir(), ".zshrc");
      await copyToClipboard(`nvim ${shellQuote(file)}`).catch(() => undefined);
      await openWarpNvim(ctx.cwd, file).catch(() => undefined);
      ctx.ui.notify(`Opening ~/.zshrc in nvim`, "info");
    },
  });
}
