import { defineConfig } from "vitest/config";

// Un seul worker de test : la machine de dev a 3,8 Go de RAM (Risk Register
// R11). Les tests sont purs (mocks reseau/DB), le parallelisme n'apporte rien.
export default defineConfig({
  test: {
    include: ["test/**/*.test.ts"],
    fileParallelism: false,
    pool: "threads",
    maxWorkers: 1,
    minWorkers: 1,
    testTimeout: 10_000,
  },
});
