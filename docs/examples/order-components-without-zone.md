# Example: `OrderComponents` without `zone`, `zoneHash`, `conduitKey`

Walkthrough for **Mode B** in [custom-order-and-bulk-development.md](../custom-order-and-bulk-development.md): the EIP-712 type name stays **`OrderComponents`**; three members are removed.

**Implemented in this repo (does not modify `SeaportLite`):**

| Piece                   | Path                                                                                                                                                                          |
| ----------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Contract                | [`src/CustomBulkSeaport.sol`](../../src/CustomBulkSeaport.sol)                                                                                                                |
| Variant sources         | [`src/variants/`](../../src/variants/) — `CustomConsideration`, `CustomConsiderationBase`, `CustomBulkOrderTypeHashHelp`, …                                                   |
| Solidity structs        | `CustomOrderComponents`, `CustomOrder`, `CustomOfferItem`, `CustomConsiderationItem` in [`CustomConsiderationStructs.sol`](../../src/variants/CustomConsiderationStructs.sol) |
| Tests                   | [`test/CustomBulkSeaport.t.sol`](../../test/CustomBulkSeaport.t.sol)                                                                                                          |
| Bulk typehash generator | `forge test --match-contract GenerateCustomBulkOrderTypeHash -vv`                                                                                                             |
| Sign / FFI              | `npm run sign-order-custom-bulk`, `tsx test/helpers/custom-bulk-seaport-test.ts export single`                                                                                |
| EIP-712 TS              | [`test/helpers/custom-bulk-eip712.ts`](../../test/helpers/custom-bulk-eip712.ts)                                                                                              |

Domain: `CustomBulkSeaport` / `1.0` — deploy address in tests: `0x00000000000000000000000000000000000000DE`.

**Naming:** Solidity uses the `Custom*` prefix for structs/contracts; EIP-712 **type strings** remain `OrderComponents`, `OfferItem`, `ConsiderationItem`, `BulkOrder`.

| Removed field | Typical Seaport role                        | After removal                                 |
| ------------- | ------------------------------------------- | --------------------------------------------- |
| `zone`        | Restricted-order controller / cancel helper | No on-chain zone checks in lite (already N/A) |
| `zoneHash`    | Opaque data for zone contracts              | Omit from signature                           |
| `conduitKey`  | Token routing via Conduit                   | Signer / app must transfer tokens elsewhere   |

`OfferItem` / `ConsiderationItem` are unchanged in this example.

---

## 1. Solidity struct

In-repo struct name: `CustomOrderComponents` (EIP-712 type name still `OrderComponents`):

```solidity
struct CustomOrderComponents {
  address offerer;
  // zone removed
  CustomOfferItem[] offer;
  CustomConsiderationItem[] consideration;
  OrderType orderType;
  uint256 startTime;
  uint256 endTime;
  // zoneHash removed
  uint256 salt;
  // conduitKey removed
  uint256 counter;
}
```

---

## 2. EIP-712 `encodeType` strings

**Primary type** (`OrderComponents` only):

```text
OrderComponents(address offerer,OfferItem[] offer,ConsiderationItem[] consideration,uint8 orderType,uint256 startTime,uint256 endTime,uint256 salt,uint256 counter)
```

**Full `encodeType(OrderComponents)`** (primary + dependencies **C**onsiderationItem before **O**fferItem):

```text
OrderComponents(address offerer,OfferItem[] offer,ConsiderationItem[] consideration,uint8 orderType,uint256 startTime,uint256 endTime,uint256 salt,uint256 counter)ConsiderationItem(uint8 itemType,address token,uint256 identifierOrCriteria,uint256 startAmount,uint256 endAmount,address recipient)OfferItem(uint8 itemType,address token,uint256 identifierOrCriteria,uint256 startAmount,uint256 endAmount)
```

Verify:

```bash
cast keccak "OrderComponents(address offerer,OfferItem[] offer,ConsiderationItem[] consideration,uint8 orderType,uint256 startTime,uint256 endTime,uint256 salt,uint256 counter)ConsiderationItem(uint8 itemType,address token,uint256 identifierOrCriteria,uint256 startAmount,uint256 endAmount,address recipient)OfferItem(uint8 itemType,address token,uint256 identifierOrCriteria,uint256 startAmount,uint256 endAmount)"
```

Set `_ORDER_TYPEHASH` to that value in your contract constructor / immutables.

---

## 3. `CustomConsiderationBase._deriveTypehashes()`

Update only the `orderComponentsPartialTypeString` literal (keep `bytes.concat` order: primary, then `considerationItemTypeString`, then `offerItemTypeString`):

```solidity
bytes memory orderComponentsPartialTypeString = bytes(
    "OrderComponents("
    "address offerer,"
    "OfferItem[] offer,"
    "ConsiderationItem[] consideration,"
    "uint8 orderType,"
    "uint256 startTime,"
    "uint256 endTime,"
    "uint256 salt,"
    "uint256 counter"
    ")"
);
```

---

## 4. `CustomConsideration.hashOrderComponents`

`abi.encode` must list **exactly** the struct fields in EIP-712 order (no `zone` / `zoneHash` / `conduitKey`):

```solidity
return keccak256(
    abi.encode(
        _ORDER_TYPEHASH,
        order.offerer,
        keccak256(abi.encodePacked(offerHashes)),
        keccak256(abi.encodePacked(considerationHashes)),
        order.orderType,
        order.startTime,
        order.endTime,
        order.salt,
        _getCounter(order.offerer)
    )
);
```

---

## 5. Bulk (`CustomBulkOrderTypeHashHelp`)

- **Unchanged:** `BulkOrder(OrderComponents` + `[2]…` + ` tree)` prefix — still named `OrderComponents`.
- **Change:** same `orderComponentsPartialTypeString` as §3 inside `getTreeSubTypes()` in [`CustomBulkOrderTypeHashHelp.sol`](../../src/variants/CustomBulkOrderTypeHashHelp.sol).
- **Re-run:** `getBulkOrderTypeHashs()` → replace all `CustomBulkOrder_Typehash_Height_*` in [`CustomConsiderationConstants.sol`](../../src/variants/CustomConsiderationConstants.sol).

```bash
forge test --match-contract GenerateCustomBulkOrderTypeHash -vv
```

Bulk height-1 type string shape:

```text
BulkOrder(OrderComponents[2] tree)ConsiderationItem(...)OfferItem(...)OrderComponents(address offerer,OfferItem[] offer,...)
```

---

## 6. TypeScript / FFI

Types (ethers v6). Declare the types map as `Record<string, TypedDataField[]>` — **do not** use `as const` on the whole object (ethers expects mutable `TypedDataField[]`). See [`custom-bulk-eip712.ts`](../../test/helpers/custom-bulk-eip712.ts).

When signing, set the `counter` field to **`getCounter(offerer)`** on `CustomBulkSeaport` at sign time (fixtures use `0`). On-chain verification hashes storage counter via `_getCounter(offerer)` — same as `SeaportLite`.

```typescript
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
```

**FFI ABI tuple** (for `vm.ffi` / `AbiCoder.encode`):

```text
tuple(address,tuple(uint8,address,uint256,uint256,uint256)[],tuple(uint8,address,uint256,uint256,uint256,address)[],uint8,uint256,uint256,uint256,uint256)
```

Copy-ready module: [`templates/eip712-types.custom.template.ts`](../templates/eip712-types.custom.template.ts) (mirrored by [`test/helpers/custom-bulk-eip712.ts`](../../test/helpers/custom-bulk-eip712.ts)).

---

## 7. Compatibility warning

|                             | Standard Seaport `OrderComponents` | This example                          |
| --------------------------- | ---------------------------------- | ------------------------------------- |
| type name                   | `OrderComponents`                  | `OrderComponents`                     |
| typeHash                    | Seaport 1.5 value                  | **Different**                         |
| Signatures                  | OpenSea / Seaport JS               | **Not interchangeable**               |
| bulkorder-sdk default types | Includes zone fields               | Must fork types or use your TS module |

---

## 8. Checklist (this example)

- [ ] `CustomConsiderationStructs.CustomOrderComponents` — 3 fields removed; EIP-712 name still `OrderComponents`
- [ ] `CustomConsiderationBase._deriveTypehashes` + `CustomConsideration.hashOrderComponents` — §3–4
- [ ] `CustomBulkOrderTypeHashHelp.getTreeSubTypes` — §3 string
- [ ] `CustomConsiderationConstants` bulk hashes regenerated (`GenerateCustomBulkOrderTypeHash`)
- [ ] `test/helpers/custom-bulk-seaport-test.ts` + `ORDER_COMPONENTS_CUSTOM_BULK_ABI` — §6
- [ ] `CustomBulkSeaport.t.sol` / `test_orderTypehashConstant` green
- [ ] Document that orders are **not** valid on mainnet Seaport
