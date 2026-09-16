import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";
import { spawn } from "node:child_process";
import { existsSync } from "node:fs";
import { dirname, isAbsolute, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const helperPath = resolve(__dirname, "helper.py");

type HelperPayload = Record<string, unknown> & { action: string; file: string };

function resolveFile(cwd: string, file: string): string {
  return isAbsolute(file) ? file : resolve(cwd, file);
}

function runHelper(payload: HelperPayload, cwd: string, signal?: AbortSignal): Promise<any> {
  const uv = resolve(cwd, "bin", "uv");
  const cmd = existsSync(uv) ? uv : "uv";
  const args = ["run", "--with", "libcst", "python", helperPath];

  return new Promise((resolvePromise) => {
    const child = spawn(cmd, args, { cwd, env: process.env });
    let out = "";
    let err = "";

    const abort = () => child.kill("SIGTERM");
    signal?.addEventListener("abort", abort, { once: true });

    child.stdout?.setEncoding("utf8");
    child.stderr?.setEncoding("utf8");
    child.stdout?.on("data", (chunk) => { out += chunk; });
    child.stderr?.on("data", (chunk) => { err += chunk; });
    child.on("error", (error) => {
      signal?.removeEventListener("abort", abort);
      resolvePromise({ ok: false, error: String(error) });
    });
    child.on("close", (code) => {
      signal?.removeEventListener("abort", abort);
      if (code !== 0) {
        resolvePromise({ ok: false, error: `helper exited ${code}`, stderr: err, stdout: out });
        return;
      }
      try {
        resolvePromise(JSON.parse(out));
      } catch (error) {
        resolvePromise({ ok: false, error: `Could not parse helper JSON: ${error}`, stderr: err, stdout: out });
      }
    });
    child.stdin.end(JSON.stringify(payload));
  });
}

function resultText(result: any): string {
  if (!result?.ok) return `Python refactor tool failed: ${result?.error ?? "unknown error"}`;
  if (result.symbols) {
    const rows = result.symbols.map((s: any) => `${s.kind.padEnd(8)} ${s.name} (${s.startLine}-${s.endLine})`);
    return rows.length ? rows.join("\n") : "No top-level Python symbols found.";
  }
  if (result.changed) {
    return `Updated ${result.file}\nOld order: ${result.oldOrder.join(", ")}\nNew order: ${result.newOrder.join(", ")}`;
  }
  return result.message ?? JSON.stringify(result, null, 2);
}

export default function pythonRefactor(pi: ExtensionAPI) {
  const refactorGuidelines = [
    "Use list_python_symbols before large Python refactors to inspect available top-level functions/classes and line ranges.",
    "Use list_python_class_symbols before reordering methods within a Python class.",
    "Use sort_python_members, move_python_member, sort_python_class_members, or move_python_class_member instead of raw edit/write when reordering Python functions/classes/methods.",
    "Prefer Python symbol/PyCST tools for structural Python refactors; use edit only for small localized text changes.",
  ];

  pi.registerTool({
    name: "list_python_symbols",
    label: "List Python Symbols",
    description: "List top-level Python functions/classes with line ranges using LibCST metadata.",
    promptSnippet: "List top-level Python functions/classes with line ranges for refactoring.",
    promptGuidelines: refactorGuidelines,
    parameters: Type.Object({
      file: Type.String({ description: "Python file path, absolute or relative to cwd." }),
    }),
    async execute(_toolCallId, params, signal, _onUpdate, ctx) {
      const result = await runHelper({ action: "list_symbols", file: resolveFile(ctx.cwd, params.file) }, ctx.cwd, signal);
      return { content: [{ type: "text", text: resultText(result) }], details: result };
    },
  });

  pi.registerTool({
    name: "list_python_class_symbols",
    label: "List Python Class Symbols",
    description: "List methods/nested classes within a top-level Python class with line ranges using LibCST metadata.",
    promptSnippet: "List Python methods/nested classes within a class with line ranges for refactoring.",
    promptGuidelines: refactorGuidelines,
    parameters: Type.Object({
      file: Type.String({ description: "Python file path, absolute or relative to cwd." }),
      className: Type.String({ description: "Top-level class name." }),
    }),
    async execute(_toolCallId, params, signal, _onUpdate, ctx) {
      const result = await runHelper({ action: "list_class_symbols", file: resolveFile(ctx.cwd, params.file), className: params.className }, ctx.cwd, signal);
      return { content: [{ type: "text", text: resultText(result) }], details: result, isError: !result?.ok };
    },
  });

  pi.registerTool({
    name: "sort_python_members",
    label: "Sort Python Members",
    description: "Reorder top-level Python functions/classes by explicit requested layout or alphabetically while preserving formatting/comments with LibCST.",
    promptSnippet: "Reorder top-level Python functions/classes using syntax-aware LibCST transforms.",
    promptGuidelines: refactorGuidelines,
    parameters: Type.Object({
      file: Type.String({ description: "Python file path, absolute or relative to cwd." }),
      order: Type.Optional(Type.Array(Type.String(), { description: "Desired member names in order. Unspecified members remain after these in original order." })),
      alphabetical: Type.Optional(Type.Boolean({ description: "Sort all top-level functions/classes alphabetically by kind/name instead of using explicit order." })),
      dryRun: Type.Optional(Type.Boolean({ description: "Preview without writing the file." })),
    }),
    async execute(_toolCallId, params, signal, _onUpdate, ctx) {
      const result = await runHelper({
        action: "sort_members",
        file: resolveFile(ctx.cwd, params.file),
        order: params.order,
        alphabetical: params.alphabetical ?? false,
        dryRun: params.dryRun ?? false,
      }, ctx.cwd, signal);
      return { content: [{ type: "text", text: resultText(result) }], details: result, isError: !result?.ok };
    },
  });

  pi.registerTool({
    name: "move_python_member",
    label: "Move Python Member",
    description: "Move one top-level Python function/class before or after another using LibCST while preserving formatting/comments.",
    promptSnippet: "Move one top-level Python function/class before/after another using LibCST.",
    promptGuidelines: refactorGuidelines,
    parameters: Type.Object({
      file: Type.String({ description: "Python file path, absolute or relative to cwd." }),
      name: Type.String({ description: "Top-level function/class name to move." }),
      before: Type.Optional(Type.String({ description: "Move the member before this top-level member. Specify exactly one of before/after." })),
      after: Type.Optional(Type.String({ description: "Move the member after this top-level member. Specify exactly one of before/after." })),
      dryRun: Type.Optional(Type.Boolean({ description: "Preview without writing the file." })),
    }),
    async execute(_toolCallId, params, signal, _onUpdate, ctx) {
      const result = await runHelper({
        action: "move_member",
        file: resolveFile(ctx.cwd, params.file),
        name: params.name,
        before: params.before,
        after: params.after,
        dryRun: params.dryRun ?? false,
      }, ctx.cwd, signal);
      return { content: [{ type: "text", text: resultText(result) }], details: result, isError: !result?.ok };
    },
  });

  pi.registerTool({
    name: "sort_python_class_members",
    label: "Sort Python Class Members",
    description: "Reorder methods/nested classes within a top-level Python class by explicit requested layout or alphabetically while preserving formatting/comments with LibCST.",
    promptSnippet: "Reorder methods/nested classes inside a Python class using syntax-aware LibCST transforms.",
    promptGuidelines: refactorGuidelines,
    parameters: Type.Object({
      file: Type.String({ description: "Python file path, absolute or relative to cwd." }),
      className: Type.String({ description: "Top-level class name." }),
      order: Type.Optional(Type.Array(Type.String(), { description: "Desired class member names in order. Unspecified members remain after these in original order." })),
      alphabetical: Type.Optional(Type.Boolean({ description: "Sort all methods/nested classes alphabetically by kind/name instead of using explicit order." })),
      dryRun: Type.Optional(Type.Boolean({ description: "Preview without writing the file." })),
    }),
    async execute(_toolCallId, params, signal, _onUpdate, ctx) {
      const result = await runHelper({
        action: "sort_class_members",
        file: resolveFile(ctx.cwd, params.file),
        className: params.className,
        order: params.order,
        alphabetical: params.alphabetical ?? false,
        dryRun: params.dryRun ?? false,
      }, ctx.cwd, signal);
      return { content: [{ type: "text", text: resultText(result) }], details: result, isError: !result?.ok };
    },
  });

  pi.registerTool({
    name: "move_python_class_member",
    label: "Move Python Class Member",
    description: "Move one method/nested class before or after another within a top-level Python class using LibCST while preserving formatting/comments.",
    promptSnippet: "Move one method/nested class before/after another within a Python class using LibCST.",
    promptGuidelines: refactorGuidelines,
    parameters: Type.Object({
      file: Type.String({ description: "Python file path, absolute or relative to cwd." }),
      className: Type.String({ description: "Top-level class name." }),
      name: Type.String({ description: "Method/nested class name to move." }),
      before: Type.Optional(Type.String({ description: "Move the member before this class member. Specify exactly one of before/after." })),
      after: Type.Optional(Type.String({ description: "Move the member after this class member. Specify exactly one of before/after." })),
      dryRun: Type.Optional(Type.Boolean({ description: "Preview without writing the file." })),
    }),
    async execute(_toolCallId, params, signal, _onUpdate, ctx) {
      const result = await runHelper({
        action: "move_class_member",
        file: resolveFile(ctx.cwd, params.file),
        className: params.className,
        name: params.name,
        before: params.before,
        after: params.after,
        dryRun: params.dryRun ?? false,
      }, ctx.cwd, signal);
      return { content: [{ type: "text", text: resultText(result) }], details: result, isError: !result?.ok };
    },
  });

  pi.registerCommand("python-refactor-status", {
    description: "Check whether the Python refactor/PyCST tools are available.",
    handler: async (_args, ctx) => {
      const result = await runHelper({ action: "list_symbols", file: helperPath }, ctx.cwd, ctx.signal);
      ctx.ui.notify(result?.ok ? "Python refactor tools loaded; LibCST helper works." : `Python refactor tools failed: ${result?.error}`, result?.ok ? "info" : "error");
    },
  });

  pi.on("before_agent_start", async (event) => {
    if (/python|pycst|refactor|reorder|move\s+(function|class|method)|rename|de-?slop|cleanup/i.test(event.prompt)) {
      return {
        systemPrompt: `${event.systemPrompt}\n\nFor Python structural refactors, prefer list_python_symbols, list_python_class_symbols, sort_python_members, move_python_member, sort_python_class_members, and move_python_class_member over raw text edits. Use raw edit only for localized textual changes or when the Python symbol tools cannot express the transformation.`,
      };
    }
  });
}
