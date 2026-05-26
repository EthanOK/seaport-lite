# OrderComponents / BulkOrder schema sync checklist

Check each item in your PR when changing the schema (copy into the PR description).

## A. Design

- [ ] Extension mode chosen: **A** standard Seaport fields + maybe domain / **B** custom fields inside `OrderComponents` (type name unchanged)
- [ ] New fields documented (name, type, included in signature or not)
- [ ] Confirmed EIP-712 primary type remains `OrderComponents` (not renamed)
- [ ] Still need `counter` / `salt` / `conduitKey`?

## B. Solidity

- [ ] `ConsiderationStructs.sol` updated (`struct OrderComponents` name unchanged unless intentional fork)
- [ ] `_deriveTypehashes()` updated: primary type + **dependencies (alphabetical by type name)**
- [ ] `hashOrderComponents` `abi.encode` field order matches EIP-712
- [ ] `hashOrderComponents` encodes **`_getCounter(offerer)`** (storage), not a stale calldata-only counter
- [ ] `hashOfferItem` / `hashConsiderationItem` updated (if items changed)
- [ ] `BulkOrderTypeHashHelp.getTreeSubTypes()` matches order subtypes
- [ ] Bulk still uses `BulkOrder(OrderComponents[2]… tree)` (leaf type name `OrderComponents`)
- [ ] Ran `BulkOrderTypeHashHelp.getBulkOrderTypeHashs()` and updated 24 constants in `ConsiderationConstants`
- [ ] `_lookupBulkOrderTypehash` still covers heights 1–24

## C. Off-chain TypeScript / SDK

- [ ] ethers `types` match Solidity struct fields
- [ ] `ORDER_COMPONENTS_ABI` tuple matches FFI / `abi.encode` layout
- [ ] `getSeaportDomain()` matches contract `eip712Domain()`
- [ ] bulkorder-sdk / `EIP_712_BULK_ORDER_TYPE_DEMO` updated (if using Bulk)
- [ ] Golden `orderHash` recorded via `cast keccak` or `TypedDataEncoder`

## D. Tests

- [ ] `forge test` green
- [ ] `npm run sign-order` + `test_validateSignature` (`SeaportLite`)
- [ ] `npm run sign-bulk-order` + `test_validateSignature_BulkOrder` (if Bulk supported)
- [ ] **Custom variant only:** `npm run sign-order-custom-bulk` + `CustomBulkSeaportTest`
- [ ] **Custom variant only:** `forge test --match-contract GenerateCustomBulkOrderTypeHash -vv` after bulk string changes
- [ ] Invalid signature / post-`incrementCounter` invalidates old signature (as needed)

## E. Deploy & integration

- [ ] `verifyingContract` points at new deployment
- [ ] Docs state compatibility scope vs official Seaport

## F. CustomBulkSeaport variant (if using `src/variants/`)

- [ ] `src/variants/CustomConsiderationStructs.sol` — `CustomOrderComponents` field list
- [ ] `CustomConsiderationBase` / `CustomConsideration` hashing matches EIP-712
- [ ] `CustomBulkOrderTypeHashHelp` + `CustomConsiderationConstants` in sync
- [ ] `test/helpers/custom-bulk-eip712.ts` — `Record<string, TypedDataField[]>`, no `as const` on types object
- [ ] Domain `CustomBulkSeaport` / `1.0` matches contract + TS
