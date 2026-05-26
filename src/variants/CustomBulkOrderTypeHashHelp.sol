// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {
    OneWord,
    FreeMemoryPointerSlot
} from "../lib/ConsiderationConstants.sol";

/// @dev Generates BulkOrder EIP-712 typehashes when OrderComponents omits zone / zoneHash / conduitKey.
contract CustomBulkOrderTypeHashHelp {
    bytes3 internal constant twoSubstring = 0x5B325D;
    uint256 internal constant twoSubstringLength = 0x3;
    uint256 internal constant MaxTreeHeight = 0x18;

    function getBulkOrderTypeHashs() public pure returns (bytes32[] memory) {
        bytes32[] memory typeHashes = new bytes32[](MaxTreeHeight);
        bytes memory brackets = getMaxTreeBrackets(MaxTreeHeight);
        bytes memory subTypes = getTreeSubTypes();

        uint256 freeMemoryPointer;
        assembly {
            freeMemoryPointer := mload(FreeMemoryPointerSlot)
        }

        for (uint256 i = 0; i < MaxTreeHeight; ) {
            uint256 height = i + 1;
            assembly {
                mstore(brackets, mul(twoSubstringLength, height))
            }

            bytes memory bulkOrderTypeString = bytes.concat(
                "BulkOrder(OrderComponents",
                brackets,
                " tree)",
                subTypes
            );

            typeHashes[i] = keccak256(bulkOrderTypeString);

            assembly {
                mstore(FreeMemoryPointerSlot, freeMemoryPointer)
            }

            unchecked {
                ++i;
            }
        }

        return typeHashes;
    }

    function getMaxTreeBrackets(
        uint256 maxHeight
    ) internal pure returns (bytes memory) {
        bytes memory suffixes = new bytes(twoSubstringLength * maxHeight);
        assembly {
            let ptr := add(suffixes, OneWord)
            let endPtr := add(ptr, mul(maxHeight, twoSubstringLength))
            for {} lt(ptr, endPtr) {
                ptr := add(ptr, twoSubstringLength)
            } {
                mstore(ptr, twoSubstring)
            }
        }
        return suffixes;
    }

    function getTreeSubTypes() internal pure returns (bytes memory) {
        bytes memory offerItemTypeString = bytes(
            "OfferItem("
            "uint8 itemType,"
            "address token,"
            "uint256 identifierOrCriteria,"
            "uint256 startAmount,"
            "uint256 endAmount"
            ")"
        );

        bytes memory considerationItemTypeString = bytes(
            "ConsiderationItem("
            "uint8 itemType,"
            "address token,"
            "uint256 identifierOrCriteria,"
            "uint256 startAmount,"
            "uint256 endAmount,"
            "address recipient"
            ")"
        );

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

        return
            bytes.concat(
                considerationItemTypeString,
                offerItemTypeString,
                orderComponentsPartialTypeString
            );
    }
}
