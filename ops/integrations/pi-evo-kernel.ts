import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { execFileSync } from "node:child_process";

const EVO = "/Users/zodyne/Dev/evo-kernel/bin/evo";

/** fail-open：任何故障返回空串，绝不阻塞 harness */
const call = (sub: string, stdinJson?: object, args: string[] = []): string => {
  try {
    return execFileSync(EVO, [sub, ...args], {
      input: stdinJson ? JSON.stringify(stdinJson) : undefined,
      timeout: 6000,
    }).toString().trim();
  } catch {
    return "";
  }
};

/** 无 UI 模式（print/json）下静默跳过 */
const tell = (ctx: any, msg: string, level: "info" | "warning" = "info") => {
  try { if (ctx.hasUI) ctx.ui.notify(msg, level); } catch {}
};

export default function (pi: ExtensionAPI) {
  // 开工注入：首条 prompt 触发 recall（CLI 内部按 session 去重、空命中不占名额）
  pi.on("before_agent_start", async (event, ctx) => {
    const out = call("hook-recall", {
      session_id: ctx.sessionManager.getSessionId(),
      prompt: event.prompt,
    });
    if (!out) return;
    return { message: { customType: "evo-recall", content: out, display: false } };
  });

  // 会话结束登记：引用入 inbox，蒸馏延后批处理（零成本零打扰）
  pi.on("session_shutdown", async (_event, ctx) => {
    const file = ctx.sessionManager.getSessionFile();
    // 无会话文件 = `--no-session` 的一次性调用，后台蒸馏驱动器正是这么跑 pi 的。
    // 登记它只会写出一条 transcript:'?' 的哨兵行：永远进不了蒸馏队列（queue 跳过 '?'），
    // 却会灌高 doctor 的哨兵率和 reflect 的「蒸馏节律」判据。实测 22 条 pi 哨兵的时间戳
    // 与 distill.log 的 done 时刻逐条吻合——蒸馏跑得越勤，指标越显示"transcript 腐烂
    // 加剧、该缩短蒸馏周期"，是系统用自己的运行噪声驱动自己的治理决策。
    if (!file) return;
    call("hook-session-end", {
      session_id: ctx.sessionManager.getSessionId(),
      transcript_path: file,
      harness: "pi", // 不传则 CLI 默认 'claude'，pi 会话会被误标
    });
  });

  pi.registerCommand("capture", {
    description: "evo capture：一句话进 kernel inbox（零判断）",
    handler: async (args, ctx) => {
      const out = call("capture", undefined, [args || ""]);
      tell(ctx, out || "capture 失败（fail-open，未阻塞）", out ? "info" : "warning");
    },
  });

  pi.registerCommand("learn", {
    description: "evo learn：收工蒸馏指引（slice→对账→提案→人审→curate）",
    handler: async (_args, ctx) => {
      const file = ctx.sessionManager.getSessionFile();
      tell(ctx,
        `蒸馏流程：① evo slice --session ${file ?? "<session>"} --ids ${ctx.sessionManager.getSessionId()} ② 写提案到 ~/Dev/evo-kernel/ops/proposals/（triggers 必填）③ 人审后 evo curate --file <f> --to <dir>`,
      );
    },
  });

  pi.registerCommand("reflect", {
    description: "evo reflect：刷新 manifest 并显示库状态",
    handler: async (_args, ctx) => {
      const out = call("index", undefined, ["rebuild"]);
      tell(ctx, out || "rebuild 失败（fail-open）", out ? "info" : "warning");
    },
  });

  // solidified 硬约束层（fail-close 的唯一位置；规则来自 ~/Dev/evo-kernel/ops/constraints/，
  // 准入三条件见 blueprint §10；新规则默认 warn 观察期，reflect 评估后才升 block）
  pi.on("tool_call", async (event, ctx) => {
    const out = call("guard", undefined, [
      "--tool", event.toolName,
      "--input-json", JSON.stringify(event.input ?? {}),
    ]);
    if (!out) return;
    try {
      const v = JSON.parse(out);
      if (v.action === "deny") {
        return { block: true, reason: `[evo-constraint:${v.rule}] ${v.message}` };
      }
      if (v.action === "warn") {
        // R6 对齐 Claude 侧（§10 要件）：warn 必须对用户可见，否则观察期只有裸计数、评估不了误报
        tell(ctx, `⚠ [evo-guard:${v.rule}] ${v.message}`, "warning");
      }
    } catch {}
  });
}
