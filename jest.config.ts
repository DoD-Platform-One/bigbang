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
  globalTeardown: "./test/teardown.ts",
  watchPathIgnorePatterns: ["<rootDir>/src/assets/*.json"],
  // Needed for ECMAScript Modules aka import name.js
  moduleDirectories: ["node_modules", "src", "test"],
  moduleNameMapper: {
    "^(\\.\\.?\\/.+)\\.jsx?$": "$1",
    // '@/(.*)': '/src/$1'
  },
};

export default config;
