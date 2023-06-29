import dotenv from "dotenv";
import type { Config } from "@jest/types";

dotenv.config({
  path: "./.test.env",
});

process.env.ENVIRONMENT = "test";

// Sync object
const config: Config.InitialOptions = {
  transform: {'\\.[jt]sx?$': ['ts-jest', { useESM: true }] },
  testMatch: ["**/*.test.+(ts|tsx|js)"],
  moduleFileExtensions: ["ts", "tsx", "js", "jsx", "json", "node"],
  setupFiles: ["dotenv/config"],
  globalSetup: "./test/setup.ts",
  globalTeardown: "./test/teardown.ts",
  watchPathIgnorePatterns: ["<rootDir>/test/fixtures"],
  // Needed for ECMAScript Modules aka import name.js
  moduleNameMapper: {
    "^(\\.\\.?\\/.+)\\.jsx?$": "$1"
  }
};

export default config;
