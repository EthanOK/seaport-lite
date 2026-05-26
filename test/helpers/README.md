# Test helpers (TypeScript)

Shared signing and Forge FFI export. Requires `PRIVATE_KEY` in `.env` (see `.env.example`).

| File                          | Contract            | Domain                                      |
| ----------------------------- | ------------------- | ------------------------------------------- |
| `wallet.ts`                   | —                   | `requireSigner`, `resolveOfferer`           |
| `seaport-test.ts`             | `SeaportLite`       | `Seaport` / `1.5`                           |
| `custom-bulk-eip712.ts`       | `CustomBulkSeaport` | `CustomBulkSeaport` / `1.0` — EIP-712 types |
| `custom-bulk-seaport-test.ts` | `CustomBulkSeaport` | fixtures, sign, FFI `export`                |

## Commands

```bash
# SeaportLite
npm run sign-order
npm run sign-bulk-order
npx tsx test/helpers/seaport-test.ts export single

# CustomBulkSeaport (no zone / zoneHash / conduitKey in OrderComponents)
npm run sign-order-custom-bulk
npm run sign-bulk-order-custom-bulk
npx tsx test/helpers/custom-bulk-seaport-test.ts export bulk
```

Forge: `test/SeaportLite.t.sol` and `test/CustomBulkSeaport.t.sol` call these via `vm.ffi`. See `package.json` scripts.

**Counter:** fixtures use `counter: 0n`; on-chain hash uses `getCounter(offerer)`. After `incrementCounter()`, re-sign or tests will fail.
