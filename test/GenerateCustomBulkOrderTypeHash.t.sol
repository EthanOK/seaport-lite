// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Test, console } from "forge-std/Test.sol";
import { CustomBulkOrderTypeHashHelp } from "../src/variants/CustomBulkOrderTypeHashHelp.sol";

/// @dev Run: forge test --match-contract GenerateCustomBulkOrderTypeHash -vv
contract GenerateCustomBulkOrderTypeHash is Test {
    function test_logCustomBulkOrderTypeHashes() public {
        bytes32[] memory hashes = (new CustomBulkOrderTypeHashHelp())
            .getBulkOrderTypeHashs();
        for (uint256 i = 0; i < hashes.length; i++) {
            console.log("height", i + 1);
            console.logBytes32(hashes[i]);
        }
    }
}
