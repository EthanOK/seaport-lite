/**
 * EIP-712 types template: custom fields inside OrderComponents (type name unchanged).
 *
 * Usage:
 * 1. Copy to test/helpers/my-order-types.ts (or fork custom-bulk-eip712.ts for CustomBulkSeaport)
 * 2. Edit OrderComponents / OfferItem / ConsiderationItem fields — keep type names
 * 3. encodeType order: primary type first, then dependencies sorted by type name
 * 4. Type strings must match Solidity _deriveTypehashes() exactly (no spaces)
 *
 * See: docs/custom-order-and-bulk-development.md
 */

import { TypedDataEncoder, TypedDataField } from "ethers";

// --- Must match your deployment (domain can differ from Seaport mainnet) ---
export const CUSTOM_DOMAIN = {
  name: "MyMarket",
  version: "1.0",
  chainId: 11155111,
  verifyingContract: "0x0000000000000000000000000000000000000000", // set after deploy
} as const;

/**
 * Mode B example: extra bytes32 orderId on OrderComponents.
 * Removing zone / zoneHash / conduitKey: see eip712-types.custom.template.ts
 * encodeType concatenation (no spaces):
 *   OrderComponents(...) + ConsiderationItem(...) + OfferItem(...)
 */
export const CUSTOM_EIP712_TYPES: Record<string, TypedDataField[]> = {
  OfferItem: [
    { name: "itemType", type: "uint8" },
    { name: "token", type: "address" },
    { name: "identifierOrCriteria", type: "uint256" },
    { name: "startAmount", type: "uint256" },
    { name: "endAmount", type: "uint256" },
  ],
  ConsiderationItem: [
    { name: "itemType", type: "uint8" },
    { name: "token", type: "address" },
    { name: "identifierOrCriteria", type: "uint256" },
    { name: "startAmount", type: "uint256" },
    { name: "endAmount", type: "uint256" },
    { name: "recipient", type: "address" },
  ],
  OrderComponents: [
    { name: "offerer", type: "address" },
    { name: "zone", type: "address" },
    { name: "offer", type: "OfferItem[]" },
    { name: "consideration", type: "ConsiderationItem[]" },
    { name: "orderType", type: "uint8" },
    { name: "startTime", type: "uint256" },
    { name: "endTime", type: "uint256" },
    { name: "zoneHash", type: "bytes32" },
    { name: "salt", type: "uint256" },
    { name: "conduitKey", type: "bytes32" },
    { name: "counter", type: "uint256" },
    { name: "orderId", type: "bytes32" }, // example added field
  ],
  BulkOrder: [{ name: "tree", type: "OrderComponents[2]" }],
} as const;

export type CustomOrderComponents = {
  offerer: string;
  zone: string;
  offer: Array<{
    itemType: number;
    token: string;
    identifierOrCriteria: bigint;
    startAmount: bigint;
    endAmount: bigint;
  }>;
  consideration: Array<{
    itemType: number;
    token: string;
    identifierOrCriteria: bigint;
    startAmount: bigint;
    endAmount: bigint;
    recipient: string;
  }>;
  orderType: number;
  startTime: bigint;
  endTime: bigint;
  zoneHash: string;
  salt: bigint;
  conduitKey: string;
  counter: bigint;
  orderId: string;
};

/** structHash — compare to getOrderStructHash on-chain */
export function orderComponentsStructHash(
  order: CustomOrderComponents,
): string {
  return TypedDataEncoder.hashStruct(
    "OrderComponents",
    CUSTOM_EIP712_TYPES,
    order,
  );
}

/** Forge FFI tuple — field order must match struct OrderComponents in Solidity */
export const ORDER_COMPONENTS_ABI =
  "tuple(address,address,tuple(uint8,address,uint256,uint256,uint256)[],tuple(uint8,address,uint256,uint256,uint256,address)[],uint8,uint256,uint256,bytes32,uint256,bytes32,uint256,bytes32)";
