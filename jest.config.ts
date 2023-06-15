import dotenv from "dotenv";
import type {Config} from '@jest/types';

dotenv.config({
    path: "./.test.env"
});

process.env.ENVIRONMENT = 'test';

// Sync object
const config: Config.InitialOptions = {
  roots: ['<rootDir>/test/'],
  transform: {
    '^.+\\.tsx?$': 'ts-jest'
  },
  testMatch: [
    "**/*.test.+(ts|tsx|js)"
  ],
  moduleFileExtensions: ['ts', 'tsx', 'js', 'jsx', 'json', 'node'],
  setupFiles: ["dotenv/config"],
  globalTeardown: './test/teardown.ts'
};

export default config;


