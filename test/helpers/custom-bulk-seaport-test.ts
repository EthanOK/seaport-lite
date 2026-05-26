/**
 * CustomBulkSeaport: sign / FFI export (OrderComponents without zone fields).
 *
 *   tsx test/helpers/custom-bulk-seaport-test.ts sign <single|bulk>
 *   tsx test/helpers/custom-bulk-seaport-test.ts export <single|bulk>
 */
import { BulkOrder } from "bulkorder-sdk";
import { AbiCoder, Wallet } from "ethers";
import { requireSigner, resolveOfferer } from "./wallet";
import {
  CUSTOM_BULK_DOMAIN,
  CUSTOM_BULK_EIP712_TYPES,
  ORDER_COMPONENTS_CUSTOM_BULK_ABI,
  type OrderComponentsCustomBulk,
} from "./custom-bulk-eip712";

type SignMode = "single" | "bulk";

function getDemoOrderComponents(
  offerer: string,
  forForge?: boolean,
): OrderComponentsCustomBulk {
  const ref = forForge ? 1n : BigInt(Math.floor(Date.now() / 1000));
  const startTime = ref;
  const endTime = ref + 30n * 24n * 60n * 60n;

  return {
    offerer,
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
    salt: 24446860302761739304752683030156737591518664810215442929818227897836383814680n,
    counter: 0n,
  };
}

function orderComponentsTuple(o: OrderComponentsCustomBulk) {
  return [
    o.offerer,
    o.offer.map((item) => [
      item.itemType,
      item.token,
      item.identifierOrCriteria,
      item.startAmount,
      item.endAmount,
    ]),
    o.consideration.map((item) => [
      item.itemType,
      item.token,
      item.identifierOrCriteria,
      item.startAmount,
      item.endAmount,
      item.recipient,
    ]),
    o.orderType,
    o.startTime,
    o.endTime,
    o.salt,
    o.counter,
  ];
}

function encodeSignedOrder(
  o: OrderComponentsCustomBulk,
  signature: string,
): string {
  return AbiCoder.defaultAbiCoder().encode(
    [ORDER_COMPONENTS_CUSTOM_BULK_ABI, "bytes"],
    [orderComponentsTuple(o), signature],
  );
}

async function signSingle(
  signer: Wallet,
  orderComponents: OrderComponentsCustomBulk,
): Promise<string> {
  const { BulkOrder: _bulk, ...orderTypes } = CUSTOM_BULK_EIP712_TYPES;
  return signer.signTypedData(CUSTOM_BULK_DOMAIN, orderTypes, orderComponents);
}

async function signOrder(
  mode: SignMode,
  signer: Wallet,
  forForge?: boolean,
): Promise<{ orderComponents: OrderComponentsCustomBulk; signature: string }> {
  const orderComponents = getDemoOrderComponents(signer.address, forForge);

  if (mode === "single") {
    const signature = await signSingle(signer, orderComponents);
    return { orderComponents, signature };
  }

  const bulkOrder = new BulkOrder<OrderComponentsCustomBulk>(
    signer,
    CUSTOM_BULK_DOMAIN,
    CUSTOM_BULK_EIP712_TYPES,
  );
  const orders = await bulkOrder.signBulkOrder([orderComponents]);
  return { orderComponents, signature: orders[0].signature };
}

function parseSignMode(arg: string | undefined): SignMode {
  if (arg === "single" || arg === "bulk") return arg;
  console.error("mode must be 'single' or 'bulk'");
  process.exit(1);
}

async function main(): Promise<void> {
  const command = process.argv[2];
  const mode = parseSignMode(process.argv[3]);

  switch (command) {
    case "sign": {
      const signer = requireSigner();
      const { orderComponents, signature } = await signOrder(mode, signer);
      console.log("offerer:", signer.address);
      console.log("mode:", mode);
      console.log("signature:", signature);
      break;
    }
    case "export": {
      resolveOfferer(process.argv[4]);
      const signer = requireSigner();
      const { orderComponents, signature } = await signOrder(
        mode,
        signer,
        true,
      );
      process.stdout.write(encodeSignedOrder(orderComponents, signature));
      break;
    }
    default:
      console.error(
        "Usage:\n" +
          "  tsx test/helpers/custom-bulk-seaport-test.ts sign <single|bulk>\n" +
          "  tsx test/helpers/custom-bulk-seaport-test.ts export <single|bulk> [offerer]",
      );
      process.exit(1);
  }
}

main().catch((err: unknown) => {
  console.error(err);
  process.exit(1);
});
