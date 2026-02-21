export type { MatrixAuth, MatrixResolvedConfig } from "./client/types.js";
export { isBunRuntime } from "./client/runtime.js";
export { resolveMatrixConfig, resolveMatrixAuth } from "./client/config.js";

/**
 * Keep heavy Matrix SDK imports lazy so config-only code paths and lightweight
 * tests don't fail at module-load time on hosts lacking required native libs.
 */
export async function createMatrixClient(
  ...args: Parameters<typeof import("./client/create-client.js").createMatrixClient>
): ReturnType<typeof import("./client/create-client.js").createMatrixClient> {
  const mod = await import("./client/create-client.js");
  return await mod.createMatrixClient(...args);
}

export async function resolveSharedMatrixClient(
  ...args: Parameters<typeof import("./client/shared.js").resolveSharedMatrixClient>
): ReturnType<typeof import("./client/shared.js").resolveSharedMatrixClient> {
  const mod = await import("./client/shared.js");
  return await mod.resolveSharedMatrixClient(...args);
}

export async function waitForMatrixSync(
  ...args: Parameters<typeof import("./client/shared.js").waitForMatrixSync>
): ReturnType<typeof import("./client/shared.js").waitForMatrixSync> {
  const mod = await import("./client/shared.js");
  return await mod.waitForMatrixSync(...args);
}

export async function stopSharedClient(
  ...args: Parameters<typeof import("./client/shared.js").stopSharedClient>
): ReturnType<typeof import("./client/shared.js").stopSharedClient> {
  const mod = await import("./client/shared.js");
  return await mod.stopSharedClient(...args);
}
