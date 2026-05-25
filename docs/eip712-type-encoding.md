# EIP-712 type encoding and `orderTypehash`

How `ConsiderationBase._deriveTypehashes()` builds `orderTypeString`: **the ordering rule is defined in EIP-712, not in Solidity comments.**

---

## Where is the order specified?

| Location | States “dependencies sorted by name”? |
|----------|--------------------------------------|
| [EIP-712 `encodeType`](https://eips.ethereum.org/EIPS/eip-712#definition-of-encodetype) | **Yes** (normative spec) |
| `src/lib/ConsiderationBase.sol` (lines ~130–139) | **No** (only `bytes.concat`; see short comment + this doc) |
| `docs/eip712-type-encoding.md` (this file) | **Yes** (explanation) |

The three-part concat in the contract follows EIP-712. If the code does not explain *why* that order is used, read the spec or this document.

---

## EIP-712 spec: `encodeType`

**Section:** [Definition of encodeType](https://eips.ethereum.org/EIPS/eip-712#definition-of-encodetype)

**Normative text:**

> The type of a struct is encoded as `name ‖ "(" ‖ member₁ ‖ "," ‖ member₂ ‖ "," ‖ … ‖ memberₙ ")"` where each member is written as `type ‖ " " ‖ name`.
>
> **If the struct type references other struct types** (and these in turn reference even more struct types), then the set of referenced struct types is **collected, sorted by name** and **appended** to the encoding.
>
> An example encoding is  
> `Transaction(Person from,Person to,Asset tx)Asset(address token,uint256 amount)Person(address wallet,string name)`.

**Summary:**

1. Encode the **primary type** first: `TypeName(fieldType fieldName,…)`.
2. Collect every **referenced struct type** used in its fields.
3. Sort those dependency types by **type name** (alphabetically) and **append** each dependency’s `encodeType` after the primary type.
4. `typeHash = keccak256(encodeType(…))` — see [hashStruct](https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct).

**Important:** Sorting is by **dependency type names** (e.g. `Asset`, `Person`), not by the order fields appear in `OrderComponents`.

---

## Official example: reading “sort + append”

Full `encodeType` example from the spec:

```text
Transaction(Person from,Person to,Asset tx)Asset(address token,uint256 amount)Person(address wallet,string name)
```

Split into three parts:

| Order | Segment | Meaning |
|-------|---------|---------|
| 1 | `Transaction(Person from,Person to,Asset tx)` | **Primary type** |
| 2 | `Asset(address token,uint256 amount)` | Dependency named **Asset** |
| 3 | `Person(address wallet,string name)` | Dependency named **Person** |

`Transaction` references `Person` and `Asset`. Alphabetically: **Asset < Person**, so append order is **Asset → Person** (matches the example).

---

## Applying this to `OrderComponents`

`OrderComponents` references (among others):

- `OfferItem[] offer`
- `ConsiderationItem[] consideration`

Dependency type names:

| Type name | First letter |
|-----------|--------------|
| `ConsiderationItem` | C |
| `OfferItem` | O |

Alphabetically: **ConsiderationItem < OfferItem** → append **ConsiderationItem**, then **OfferItem**.

Full `encodeType(OrderComponents)`:

```text
encodeType(OrderComponents) =
    "OrderComponents(...)"      -- ① primary type (first)
  + "ConsiderationItem(...)"    -- ② dependency, first alphabetically
  + "OfferItem(...)"            -- ③ dependency, second alphabetically

typeHash(OrderComponents) = keccak256( concatenation above, no spaces )
```

This matches `bytes.concat` in `ConsiderationBase.sol`.

---

## Implementation in this repo

File: `src/lib/ConsiderationBase.sol`, `_deriveTypehashes()`:

```solidity
// EIP-712 encodeType: main type first, then dependencies sorted by type name.
// See docs/eip712-type-encoding.md and EIP-712 Definition of encodeType.
bytes memory orderTypeString = bytes.concat(
    orderComponentsPartialTypeString,  // OrderComponents(...)
    considerationItemTypeString,       // ConsiderationItem(...)
    offerItemTypeString                  // OfferItem(...)
);
orderTypehash = keccak256(orderTypeString);
```

Adjacent Solidity string literals are concatenated **without spaces**, then hashed.

### Per-segment type strings (match source)

**OrderComponents (primary)**

```text
OrderComponents(address offerer,address zone,OfferItem[] offer,ConsiderationItem[] consideration,uint8 orderType,uint256 startTime,uint256 endTime,bytes32 zoneHash,uint256 salt,bytes32 conduitKey,uint256 counter)
```

**ConsiderationItem**

```text
ConsiderationItem(uint8 itemType,address token,uint256 identifierOrCriteria,uint256 startAmount,uint256 endAmount,address recipient)
```

**OfferItem**

```text
OfferItem(uint8 itemType,address token,uint256 identifierOrCriteria,uint256 startAmount,uint256 endAmount)
```

Field order **inside** each struct must match `src/lib/ConsiderationStructs.sol` (same as the EIP-712 / ABI schema field order).

---

## Verify locally (`cast keccak`)

**Full `encodeType` (single line, no spaces):**

```text
OrderComponents(address offerer,address zone,OfferItem[] offer,ConsiderationItem[] consideration,uint8 orderType,uint256 startTime,uint256 endTime,bytes32 zoneHash,uint256 salt,bytes32 conduitKey,uint256 counter)ConsiderationItem(uint8 itemType,address token,uint256 identifierOrCriteria,uint256 startAmount,uint256 endAmount,address recipient)OfferItem(uint8 itemType,address token,uint256 identifierOrCriteria,uint256 startAmount,uint256 endAmount)
```

```bash
cast keccak "OrderComponents(address offerer,address zone,OfferItem[] offer,ConsiderationItem[] consideration,uint8 orderType,uint256 startTime,uint256 endTime,bytes32 zoneHash,uint256 salt,bytes32 conduitKey,uint256 counter)ConsiderationItem(uint8 itemType,address token,uint256 identifierOrCriteria,uint256 startAmount,uint256 endAmount,address recipient)OfferItem(uint8 itemType,address token,uint256 identifierOrCriteria,uint256 startAmount,uint256 endAmount)"
```

**Expected hashes (match `ConsiderationBase` / deployed `_ORDER_TYPEHASH`):**

| Name | Value |
|------|-------|
| `orderTypehash` | `0xfa445660b7e21515a59617fcd68910b487aa5808b8abda3d78bc85df364b2c2f` |
| `offerItemTypehash` | `0xa66999307ad1bb4fde44d13a5d710bd7718e0c87c1eef68a571629fbf5b93d02` |
| `considerationItemTypehash` | `0x42d81c6929ffdc4eb27a0808e40e82516ad42296c166065de7f812492304ff6e` |

Per dependency type:

```bash
cast keccak "OfferItem(uint8 itemType,address token,uint256 identifierOrCriteria,uint256 startAmount,uint256 endAmount)"
cast keccak "ConsiderationItem(uint8 itemType,address token,uint256 identifierOrCriteria,uint256 startAmount,uint256 endAmount,address recipient)"
```

---

## TypeScript / `bulkorder-sdk`

- Script: `test/seaport-test.ts`
- Schema: `EIP_712_BULK_ORDER_TYPE_DEMO` from `bulkorder-sdk`
- ethers `TypedDataEncoder` uses the same EIP-712 rules; if you change Solidity type strings, update the TS schema too.

---

## Do not confuse: `BulkOrderTypeHashHelp`

`src/lib/BulkOrderTypeHashHelp.sol` → `getTreeSubTypes()`:

```text
ConsiderationItem + OfferItem + OrderComponents
```

Used for **bulk Merkle tree** composite types, **not** for EIP-712 `encodeType(OrderComponents)`. Bulk verification uses `Verifiers._lookupBulkOrderTypehash(height)`.

---

## Other debugging

```bash
npm run sign-order          # CLI: print orderHash / signature
forge test --match-contract SeaportLiteTest -vvv
```

```solidity
seaportLite.getOrderStructHash(orderComponents);  // structHash (includes encodeData) ≠ typeHash
```

---

## References

| Document | URL |
|----------|-----|
| EIP-712 | https://eips.ethereum.org/EIPS/eip-712 |
| encodeType | https://eips.ethereum.org/EIPS/eip-712#definition-of-encodetype |
| hashStruct | https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct |
| OpenZeppelin EIP712 | https://docs.openzeppelin.com/contracts/4.x/api/utils#EIP712 |
| Seaport overview | https://docs.opensea.io/docs/seaport-overview |
