// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { CustomConsideration } from "./variants/CustomConsideration.sol";

/// @title CustomBulkSeaport
/// @notice Bulk + single-order EIP-712 verify; OrderComponents without zone / zoneHash / conduitKey.
contract CustomBulkSeaport is CustomConsideration {}
