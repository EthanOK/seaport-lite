/**
 * EIP-712 types for CustomBulkSeaport (OrderComponents without zone fields).
 */

import { TypedDataEncoder, TypedDataField } from "ethers";

export const CUSTOM_BULK_SEAPORT_ADDRESS =
  "0x00000000000000000000000000000000000000DE" as const;

export const CUSTOM_BULK_DOMAIN = {
  name: "CustomBulkSeaport",
  version: "1.0",
  chainId: 11155111,
  verifyingContract: CUSTOM_BULK_SEAPORT_ADDRESS,
} as const;

export const CUSTOM_BULK_EIP712_TYPES: Record<string, TypedDataField[]> = {
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
    { name: "offer", type: "OfferItem[]" },
    { name: "consideration", type: "ConsiderationItem[]" },
    { name: "orderType", type: "uint8" },
    { name: "startTime", type: "uint256" },
    { name: "endTime", type: "uint256" },
    { name: "salt", type: "uint256" },
    { name: "counter", type: "uint256" },
  ],
  BulkOrder: [{ name: "tree", type: "OrderComponents[2]" }],
};

export type OrderComponentsCustomBulk = {
  offerer: string;
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
  salt: bigint;
  counter: bigint;
};

export const ORDER_COMPONENTS_CUSTOM_BULK_ABI =
  "tuple(address,tuple(uint8,address,uint256,uint256,uint256)[],tuple(uint8,address,uint256,uint256,uint256,address)[],uint8,uint256,uint256,uint256,uint256)";

export function orderComponentsStructHash(
  order: OrderComponentsCustomBulk,
): string {
  return TypedDataEncoder.hashStruct(
    "OrderComponents",
    CUSTOM_BULK_EIP712_TYPES,
    order,
  );
}
