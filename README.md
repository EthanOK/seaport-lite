# opensea order

## Documentation

- [EIP-712 `encodeType` ordering (spec + local verification)](docs/eip712-type-encoding.md)
- [Custom OrderComponents & BulkOrder development guide](docs/custom-order-and-bulk-development.md) ([checklist](docs/templates/ORDER_SCHEMA_CHECKLIST.md), [TS/Solidity templates](docs/templates/))
- [Example: OrderComponents without zone / zoneHash / conduitKey](docs/examples/order-components-without-zone.md)
- **Variant contract:** `CustomBulkSeaport` (`src/CustomBulkSeaport.sol`) — EIP-712 type name still `OrderComponents`, fewer fields; does not change `SeaportLite`. Implementation: [`src/variants/`](src/variants/), guide: [order-components-without-zone](docs/examples/order-components-without-zone.md)
- Format: `npm run prettier` (Solidity, TypeScript, Markdown under `src/`, `test/`, `docs/`, `README.md`)

## sign CustomBulkSeaport order

Same flow as `SeaportLite`, but domain `CustomBulkSeaport` / `1.0` and `OrderComponents` without `zone` / `zoneHash` / `conduitKey`. Scripts live in `test/helpers/custom-bulk-seaport-test.ts` (types in `custom-bulk-eip712.ts`).

```bash
npm run sign-order-custom-bulk       # single
npm run sign-bulk-order-custom-bulk  # bulk Merkle
forge test --match-contract CustomBulkSeaportTest -vvv
```

Regenerate on-chain bulk typehash constants after schema changes:

```bash
forge test --match-contract GenerateCustomBulkOrderTypeHash -vv
```

## sign bulk order

使用 [bulkorder-sdk](https://www.npmjs.com/package/bulkorder-sdk) 对 Seaport 订单做 EIP-712 签名（单笔或 Bulk Merkle），与 `test/SeaportLite.t.sol` 中的 domain 一致（`Seaport` / `1.5` / chainId `11155111` / verifyingContract `0x00000000000000ADc04C56Bf30aC9d3c0aAF14dC`）。

```bash
npm install
cp .env.example .env   # 填入私钥；脚本会将 offerer 设为 signer.address
npm run sign-order       # 单笔 EIP-712 签名
npm run sign-bulk-order  # Bulk Merkle 签名（含 proof + index）
```

```javascript
import { BulkOrder, EIP_712_BULK_ORDER_TYPE_DEMO } from "bulkorder-sdk";
import { Wallet } from "ethers";

const domainData = {
  name: "Seaport",
  version: "1.5",
  chainId: 11155111,
  verifyingContract: "0x00000000000000ADc04C56Bf30aC9d3c0aAF14dC",
};

const signer = new Wallet(process.env.PRIVATE_KEY);

const orderComponents = {
  offerer: signer.address,
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
      recipient: signer.address,
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
  startTime: 1686193412n,
  endTime: 1688785412n,
  zoneHash:
    "0x0000000000000000000000000000000000000000000000000000000000000000",
  salt: 24446860302761739304752683030156737591518664810215442929818227897836383814680n,
  conduitKey:
    "0x0000007b02230091a7ed01230072f7006a004d60a8d4e71d599b8104250f0000",
  counter: 0n,
};

const bulkOrder = new BulkOrder(
  signer,
  domainData,
  EIP_712_BULK_ORDER_TYPE_DEMO,
);

// 单笔
const single = await bulkOrder.signOrder(orderComponents);
await bulkOrder.verifyOrder(single, orderComponents.offerer);

// Bulk（多笔时传入数组；单笔树也会生成 bulk 格式签名）
const bulk = await bulkOrder.signBulkOrder([orderComponents]);
await bulkOrder.verifyOrders(bulk, orderComponents.offerer);
```

订单 fixture、签名与 FFI 导出均在 `test/helpers/seaport-test.ts`：`export` 供 `SeaportLite.t.sol` 的 `vm.ffi` 使用，`sign` 供 CLI（`npm run sign-order`）。

## sign opensea eip712 order with ethers

```javascript
const EIP712OpenSeaMessage = async (signer, chainId) => {
  const domainData = {
    name: "Seaport",
    version: "1.5",
    chainId: chainId,
    verifyingContract: "0x00000000000000ADc04C56Bf30aC9d3c0aAF14dC",
  };

  const types = {
    OrderComponents: [
      {
        name: "offerer",
        type: "address",
      },
      {
        name: "zone",
        type: "address",
      },
      {
        name: "offer",
        type: "OfferItem[]",
      },
      {
        name: "consideration",
        type: "ConsiderationItem[]",
      },
      {
        name: "orderType",
        type: "uint8",
      },
      {
        name: "startTime",
        type: "uint256",
      },
      {
        name: "endTime",
        type: "uint256",
      },
      {
        name: "zoneHash",
        type: "bytes32",
      },
      {
        name: "salt",
        type: "uint256",
      },
      {
        name: "conduitKey",
        type: "bytes32",
      },
      {
        name: "counter",
        type: "uint256",
      },
    ],
    OfferItem: [
      {
        name: "itemType",
        type: "uint8",
      },
      {
        name: "token",
        type: "address",
      },
      {
        name: "identifierOrCriteria",
        type: "uint256",
      },
      {
        name: "startAmount",
        type: "uint256",
      },
      {
        name: "endAmount",
        type: "uint256",
      },
    ],
    ConsiderationItem: [
      {
        name: "itemType",
        type: "uint8",
      },
      {
        name: "token",
        type: "address",
      },
      {
        name: "identifierOrCriteria",
        type: "uint256",
      },
      {
        name: "startAmount",
        type: "uint256",
      },
      {
        name: "endAmount",
        type: "uint256",
      },
      {
        name: "recipient",
        type: "address",
      },
    ],
  };

  let message = {
    offerer: "0x6278A1E803A76796a3A1f7F6344fE874ebfe94B2",
    zone: "0x004C00500000aD104D7DBd00e3ae0A5C00560C00",
    offer: [
      {
        itemType: 2,
        token: "0x97f236E644db7Be9B8308525e6506E4B3304dA7B",
        identifierOrCriteria: BigNumber.from("111"),
        startAmount: BigNumber.from("1"),
        endAmount: BigNumber.from("1"),
      },
    ],
    consideration: [
      {
        itemType: 0,
        token: "0x0000000000000000000000000000000000000000",
        identifierOrCriteria: BigNumber.from("0"),
        startAmount: BigNumber.from("1082250000000000000"),
        endAmount: BigNumber.from("1082250000000000000"),
        recipient: "0x6278A1E803A76796a3A1f7F6344fE874ebfe94B2",
      },
      {
        itemType: 0,
        token: "0x0000000000000000000000000000000000000000",
        identifierOrCriteria: BigNumber.from("0"),
        startAmount: BigNumber.from("27750000000000000"),
        endAmount: BigNumber.from("27750000000000000"),
        recipient: "0x0000a26b00c1F0DF003000390027140000fAa719",
      },
    ],
    orderType: 0,
    startTime: BigNumber.from("1686193412"),
    endTime: BigNumber.from("1688785412"),
    zoneHash:
      "0x0000000000000000000000000000000000000000000000000000000000000000",
    salt: BigNumber.from(
      "24446860302761739304752683030156737591518664810215442929818227897836383814680",
    ),
    conduitKey:
      "0x0000007b02230091a7ed01230072f7006a004d60a8d4e71d599b8104250f0000",
    counter: BigNumber.from("0"),
  };

  try {
    const orderSignature = await signer._signTypedData(
      domainData,
      types,
      message,
    );

    console.log("orderSignature:" + orderSignature);

    let orderHash = _TypedDataEncoder.from(types).hash(message);

    console.log("orderHash: " + orderHash);
  } catch (error) {}
};
```

## verify Signature in contract

```solidity
function test_validateSignature() public view {
  OfferItem[] memory offer = new OfferItem[](1);
  offer[0] = OfferItem({
    itemType: ItemType.ERC721,
    token: 0x97f236E644db7Be9B8308525e6506E4B3304dA7B,
    identifierOrCriteria: 111,
    startAmount: 1,
    endAmount: 1
  });

  ConsiderationItem[] memory consideration = new ConsiderationItem[](2);
  consideration[0] = ConsiderationItem({
    itemType: ItemType.NATIVE,
    token: address(0),
    identifierOrCriteria: 0,
    startAmount: 1082250000000000000,
    endAmount: 1082250000000000000,
    recipient: payable(address(0x6278A1E803A76796a3A1f7F6344fE874ebfe94B2))
  });
  consideration[1] = ConsiderationItem({
    itemType: ItemType.NATIVE,
    token: address(0),
    identifierOrCriteria: 0,
    startAmount: 27750000000000000,
    endAmount: 27750000000000000,
    recipient: payable(address(0x0000a26b00c1F0DF003000390027140000fAa719))
  });

  OrderComponents memory orderParameters = OrderComponents({
    offerer: 0x6278A1E803A76796a3A1f7F6344fE874ebfe94B2,
    zone: 0x004C00500000aD104D7DBd00e3ae0A5C00560C00,
    offer: offer,
    consideration: consideration,
    orderType: OrderType.FULL_OPEN,
    startTime: 1686193412,
    endTime: 1688785412,
    zoneHash: bytes32(0),
    salt: 24446860302761739304752683030156737591518664810215442929818227897836383814680,
    conduitKey: 0x0000007b02230091a7ed01230072f7006a004d60a8d4e71d599b8104250f0000,
    counter: 0
  });

  bytes
    memory signature = hex"30821bc4aefea2829e00d4dcce28c305c93c1d1ef261867ed7279fa9fca6f26548f9ac6263d68a7ea7a530987a7622d5e30ced13be2a3877fdb7f6d3ed37dee91c";

  bytes32 orderhash = seaportLite.getOrderStructHash(orderParameters);
  assertEq(
    orderhash,
    0x93615616691158f9686e276600f0cc591b902c161aae970f324f908b001d7b25
  );

  bool isValid = seaportLite.validateSignature(
    Order(orderParameters, signature)
  );
  assertEq(isValid, true);

  bytes
    memory signature_invalid = hex"89f879a6ff075f1342fb313926c36ec3e5c59fe4b369052a865a4858983f410c5b20ec90e59807db86c07a29cf9c2f1475817048429498f48251990957a2cec51b";
  isValid = seaportLite.validateSignature(
    Order(orderParameters, signature_invalid)
  );
  assertEq(isValid, false);
}
```

## Verify order in contract

`SeaportLite` exposes view functions used by integrators and tests (same pattern on `CustomBulkSeaport`):

| Function                              | What it checks                                                                                                          |
| ------------------------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| `getCounter(offerer)`                 | Per-offerer counter in storage (used when hashing orders)                                                               |
| `incrementCounter()`                  | Bumps counter (quasi-random delta); invalidates prior signatures                                                        |
| `getOrderStructHash(OrderComponents)` | EIP-712 struct hash (no signature)                                                                                      |
| `validateSignature(Order)`            | ECDSA from `offerer` over the typed-data digest; **single** and **bulk** signatures                                     |
| `validateOrder(Order)`                | Same as `validateSignature`, plus `startTime <= block.timestamp <= endTime` (`require`, reverts with `"Order expired"`) |

**Flow inside `validateSignature`:**

1. `orderHash = hashOrderComponents(parameters)` — **`counter` in the hash is `_getCounter(offerer)` (storage), not reread from a separate rule on `validateOrder`**
2. If signature length matches a bulk order → recompute hash via Merkle proof (`_computeBulkOrderProof`)
3. `digest = _hashTypedDataV4(orderHash)` (domain: `Seaport` / `1.5` / chainId / `verifyingContract`)
4. Recover signer from `signature` and compare to `parameters.offerer`

**Signing off-chain:** set `OrderComponents.counter` in the typed data to the offerer’s **`getCounter(offerer)` at sign time** (tests default to `0`). After `incrementCounter()`, old signatures fail verification.

Order + signature must use the same EIP-712 domain as signing (`test/helpers/seaport-test.ts`). See [EIP-712 type encoding](docs/eip712-type-encoding.md).

### Example (Forge test, matches `test/SeaportLite.t.sol`)

Orders and signatures come from one FFI call to `test/helpers/seaport-test.ts` (`export single` / `export bulk`), so `offerer` and `signature` stay aligned.

```solidity
import { SeaportLite } from "../src/SeaportLite.sol";
import { Order, OrderComponents } from "../src/lib/ConsiderationStructs.sol";

// seaportLite at 0x00000000000000ADc04C56Bf30aC9d3c0aAF14dC in tests; vm.chainId(11155111)

function test_validateSignature() public {
  SignedOrderFixture memory fixture = getSignedOrder("single");

  bool isValid = seaportLite.validateOrder(
    Order(fixture.components, fixture.signature)
  );
  assertEq(isValid, true);
}

function test_validateSignature_BulkOrder() public {
  SignedOrderFixture memory fixture = getSignedOrder("bulk");

  bool isValid = seaportLite.validateOrder(
    Order(fixture.components, fixture.signature)
  );
  assertEq(isValid, true);
}

function test_invalidSignature_fails() public {
  SignedOrderFixture memory fixture = getSignedOrder("single");

  bytes
    memory signatureInvalid = hex"89f879a6ff075f1342fb313926c36ec3e5c59fe4b369052a865a4858983f410c5b20ec90e59807db86c07a29cf9c2f1475817048429498f48251990957a2cec51b";

  assertFalse(
    seaportLite.validateSignature(Order(fixture.components, signatureInvalid))
  );
}

/// @dev FFI: npx tsx test/helpers/seaport-test.ts export <single|bulk>
function getSignedOrder(
  string memory mode
) internal returns (SignedOrderFixture memory fixture) {
  string[] memory inputs = new string[](5);
  inputs[0] = "npx";
  inputs[1] = "tsx";
  inputs[2] = "test/helpers/seaport-test.ts";
  inputs[3] = "export";
  inputs[4] = mode;

  bytes memory encoded = vm.ffi(inputs);
  (fixture.components, fixture.signature) = abi.decode(
    encoded,
    (OrderComponents, bytes)
  );
}
```

```bash
cp .env.example .env   # PRIVATE_KEY required for FFI
forge test --match-contract SeaportLiteTest -vvv
```

**Note:** `npm run sign-order` uses wall-clock timestamps; Forge tests use `export` with `forForge` times. Do not paste CLI signatures into tests. Details in `test/helpers/seaport-test.ts` and `docs/eip712-type-encoding.md`.
