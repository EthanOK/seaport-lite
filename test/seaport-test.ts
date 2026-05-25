/**
 * Seaport-lite test helpers: fixtures, signing, FFI export, CLI.
 *
 * Usage:
 *   tsx test/seaport-test.ts sign [single|bulk]     # print signature (CLI)
 *   tsx test/seaport-test.ts export [single|bulk]   # ABI stdout for forge vm.ffi
 */
import "dotenv/config";
import {
  BulkOrder,
  EIP_712_BULK_ORDER_TYPE_DEMO,
} from "bulkorder-sdk";
import { AbiCoder, TypedDataEncoder, Wallet } from "ethers";

// --- constants ---

export const SEAPORT_LITE_ADDRESS =
  "0x00000000000000ADc04C56Bf30aC9d3c0aAF14dC" as const;
export const CHAIN_ID = 11155111;

/** Must match EXPECTED_OFFERER in test/SeaportLite.t.sol and .env.example PRIVATE_KEY */
export const EXPECTED_OFFERER =
  "0x64c21F01dDFAaA90f55042428C6E22FB5aE10890" as const;

const THIRTY_DAYS_SECONDS = 30n * 24n * 60n * 60n;

const ORDER_COMPONENTS_ABI =
  "tuple(address,address,tuple(uint8,address,uint256,uint256,uint256)[],tuple(uint8,address,uint256,uint256,uint256,address)[],uint8,uint256,uint256,bytes32,uint256,bytes32,uint256)";

// --- types ---

export type OfferItem = {
  itemType: number;
  token: string;
  identifierOrCriteria: bigint;
  startAmount: bigint;
  endAmount: bigint;
};

export type ConsiderationItem = OfferItem & {
  recipient: string;
};

export type SeaportOrderComponents = {
  offerer: string;
  zone: string;
  offer: OfferItem[];
  consideration: ConsiderationItem[];
  orderType: number;
  startTime: bigint;
  endTime: bigint;
  zoneHash: string;
  salt: bigint;
  conduitKey: string;
  counter: bigint;
};

type FixtureOptions = { forForge?: boolean; referenceTime?: bigint };
type SignMode = "single" | "bulk";

// --- fixtures ---

export function getOrderTimeWindow(options?: FixtureOptions): {
  startTime: bigint;
  endTime: bigint;
} {
  const ref =
    options?.referenceTime ??
    (options?.forForge ? 1n : BigInt(Math.floor(Date.now() / 1000)));

  return {
    startTime: ref,
    endTime: ref + THIRTY_DAYS_SECONDS,
  };
}

export function getDemoOrderComponents(
  offerer: string,
  options?: FixtureOptions
): SeaportOrderComponents {
  const { startTime, endTime } = getOrderTimeWindow(options);

  return {
    offerer,
    zone: "0x004C00500000aD104D7DBd00e3ae0A5C00560C00",
    offer: [
      {
        itemType: 2,
        token: "0x97f236E644db7Be9B8308525e6506E4B3304dA7B",
        identifierOrCriteria: 111n,
        startAmount: 1n,
        endAmount: 1n,
      },
    ],
    consideration: [
      {
        itemType: 0,
        token: "0x0000000000000000000000000000000000000000",
        identifierOrCriteria: 0n,
        startAmount: 1082250000000000000n,
        endAmount: 1082250000000000000n,
        recipient: offerer,
      },
      {
        itemType: 0,
        token: "0x0000000000000000000000000000000000000000",
        identifierOrCriteria: 0n,
        startAmount: 27750000000000000n,
        endAmount: 27750000000000000n,
        recipient: "0x0000a26b00c1F0DF003000390027140000fAa719",
      },
    ],
    orderType: 0,
    startTime,
    endTime,
    zoneHash:
      "0x0000000000000000000000000000000000000000000000000000000000000000",
    salt: 24446860302761739304752683030156737591518664810215442929818227897836383814680n,
    conduitKey:
      "0x0000007b02230091a7ed01230072f7006a004d60a8d4e71d599b8104250f0000",
    counter: 0n,
  };
}

function orderComponentsTuple(o: SeaportOrderComponents) {
  const offer = o.offer.map((item) => [
    item.itemType,
    item.token,
    item.identifierOrCriteria,
    item.startAmount,
    item.endAmount,
  ]);
  const consideration = o.consideration.map((item) => [
    item.itemType,
    item.token,
    item.identifierOrCriteria,
    item.startAmount,
    item.endAmount,
    item.recipient,
  ]);

  return [
    o.offerer,
    o.zone,
    offer,
    consideration,
    o.orderType,
    o.startTime,
    o.endTime,
    o.zoneHash,
    o.salt,
    o.conduitKey,
    o.counter,
  ];
}

export function encodeSignedOrder(
  o: SeaportOrderComponents,
  signature: string
): string {
  return AbiCoder.defaultAbiCoder().encode(
    [ORDER_COMPONENTS_ABI, "bytes"],
    [orderComponentsTuple(o), signature]
  );
}

// --- signing ---

export function requireSigner(): Wallet {
  const privateKey = process.env.PRIVATE_KEY;
  if (!privateKey) {
    console.error("PRIVATE_KEY is required in .env or the environment.");
    process.exit(1);
  }
  return new Wallet(privateKey);
}

export function resolveOfferer(cliOfferer?: string): string {
  const signer = requireSigner();
  if (
    cliOfferer &&
    cliOfferer.toLowerCase() !== signer.address.toLowerCase()
  ) {
    console.error(
      `offerer mismatch: passed ${cliOfferer}, wallet is ${signer.address}`
    );
    process.exit(1);
  }
  return signer.address;
}

function getSeaportDomain() {
  return {
    name: "Seaport",
    version: "1.5",
    chainId: CHAIN_ID,
    verifyingContract: SEAPORT_LITE_ADDRESS,
  };
}

export function orderHash(orderComponents: SeaportOrderComponents): string {
  const { BulkOrder: _b, ...types } = EIP_712_BULK_ORDER_TYPE_DEMO;
  return TypedDataEncoder.hashStruct(
    "OrderComponents",
    types,
    orderComponents
  );
}

export async function signOrder(
  mode: SignMode,
  signer: Wallet = requireSigner(),
  fixtureOptions?: FixtureOptions
): Promise<{ orderComponents: SeaportOrderComponents; signature: string }> {
  const orderComponents = getDemoOrderComponents(
    signer.address,
    fixtureOptions
  );
  const bulkOrder = new BulkOrder<SeaportOrderComponents>(
    signer,
    getSeaportDomain(),
    EIP_712_BULK_ORDER_TYPE_DEMO
  );

  if (mode === "bulk") {
    const orders = await bulkOrder.signBulkOrder([orderComponents]);
    return { orderComponents, signature: orders[0].signature };
  }

  const order = await bulkOrder.signOrder(orderComponents);
  return { orderComponents, signature: order.signature };
}

// --- commands ---

function parseSignMode(arg: string | undefined): SignMode {
  if (arg === "single" || arg === "bulk") return arg;
  console.error("mode must be 'single' or 'bulk'");
  process.exit(1);
}

function toSolidityHexBytes(signature: string): string {
  const hex = signature.startsWith("0x") ? signature.slice(2) : signature;
  return `hex"${hex}"`;
}

async function cmdSign(mode: SignMode): Promise<void> {
  const signer = requireSigner();
  const { orderComponents, signature } = await signOrder(mode, signer);

  console.log("offerer:", signer.address);
  console.log("orderHash:", orderHash(orderComponents));
  console.log("mode:", mode === "bulk" ? "bulk (Merkle)" : "single (EIP-712)");
  console.log("signature:", signature);
  console.log("solidity:", toSolidityHexBytes(signature));
}

async function cmdExport(mode: SignMode, cliOfferer?: string): Promise<void> {
  const offerer = resolveOfferer(cliOfferer);
  const { orderComponents, signature } = await signOrder(mode, undefined, {
    forForge: true,
  });

  if (orderComponents.offerer.toLowerCase() !== offerer.toLowerCase()) {
    console.error("internal error: signed order offerer mismatch");
    process.exit(1);
  }

  process.stdout.write(encodeSignedOrder(orderComponents, signature));
}

async function main(): Promise<void> {
  const command = process.argv[2];
  const mode = parseSignMode(process.argv[3]);

  switch (command) {
    case "sign":
      await cmdSign(mode);
      break;
    case "export":
      await cmdExport(mode, process.argv[4]);
      break;
    default:
      console.error(
        "Usage:\n" +
          "  tsx test/seaport-test.ts sign <single|bulk>\n" +
          "  tsx test/seaport-test.ts export <single|bulk> [offerer]"
      );
      process.exit(1);
  }
}

main().catch((err: unknown) => {
  console.error(err);
  process.exit(1);
});
