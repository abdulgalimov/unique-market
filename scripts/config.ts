import * as dotenv from "dotenv";
dotenv.config();

export interface NetworkConfig {
  rpcUrl: string;
  collectionId: number;
  tokenId: number;
}

export interface Config {
  accounts: string[];
  sdkBaseUrl: string;

  unq: NetworkConfig;
  opal: NetworkConfig;
}

const env: Record<string, any> = process.env;

function loadNetwork(prefix: string): NetworkConfig {
  return {
    rpcUrl: env[`${prefix}_RPC_URL`],
    collectionId: +env[`${prefix}_COLLECTION_ID`] || 0,
    tokenId: +env[`${prefix}_TOKEN_ID`] || 0,
  };
}

export function loadConfig(): Config {
  return {
    unq: loadNetwork("UNQ"),
    opal: loadNetwork("OPAL"),
    accounts: env["ACCOUNTS"] ? env["ACCOUNTS"].split(",") : [],
    sdkBaseUrl: env["SDK_BASE_URL"],
  };
}
