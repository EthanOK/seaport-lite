// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { OneWord, FreeMemoryPointerSlot } from "./ConsiderationConstants.sol";

contract BulkOrderTypeHashHelp {
    // Encodes "[2]" for use in deriving typehashes.
    bytes3 internal constant twoSubstring = 0x5B325D;
    uint256 internal constant twoSubstringLength = 0x3;

    // Dictates maximum bulk order group size; 24 => 2^24 => 16,777,216 orders.
    uint256 internal constant MaxTreeHeight = 0x18;

    function getBulkOrderTypeHashs() public pure returns (bytes32[] memory) {
        // Declare an array where each type hash will be written.
        bytes32[] memory typeHashes = new bytes32[](MaxTreeHeight);

        // Derive a string of 24 "[2]" substrings.
        bytes memory brackets = getMaxTreeBrackets(MaxTreeHeight);

        // Derive a string of subtypes for the order parameters.
        bytes memory subTypes = getTreeSubTypes();

        // Cache memory pointer before each loop so memory doesn't expand by the
        // full string size on each loop.
        uint256 freeMemoryPointer;
        assembly {
            freeMemoryPointer := mload(FreeMemoryPointerSlot)
        }

        for (uint256 i = 0; i < MaxTreeHeight; ) {
            // The actual height is one greater than its respective index.
            uint256 height = i + 1;

            // Slice brackets length to size needed for `height`.
            assembly {
                mstore(brackets, mul(twoSubstringLength, height))
            }

            // Encode the type string for the BulkOrder struct.
            bytes memory bulkOrderTypeString = bytes.concat(
                "BulkOrder(OrderComponents",
                brackets,
                " tree)",
                subTypes
            );

            // Derive EIP712 type hash.
            bytes32 typeHash = keccak256(bulkOrderTypeString);
            typeHashes[i] = typeHash;

            // Reset the free memory pointer.
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
            // Retrieve the pointer to the array head.
            let ptr := add(suffixes, OneWord)

            // Derive the terminal pointer.
            let endPtr := add(ptr, mul(maxHeight, twoSubstringLength))

            // Iterate over each pointer until terminal pointer is reached.
            for {} lt(ptr, endPtr) {
                ptr := add(ptr, twoSubstringLength)
            } {
                // Insert "[2]" substring directly at current pointer location.
                mstore(ptr, twoSubstring)
            }
        }

        // Return the fully populated array of substrings.
        return suffixes;
    }

    function getTreeSubTypes() internal pure returns (bytes memory) {
        // Construct the OfferItem type string.
        bytes memory offerItemTypeString = bytes(
            "OfferItem("
            "uint8 itemType,"
            "address token,"
            "uint256 identifierOrCriteria,"
            "uint256 startAmount,"
            "uint256 endAmount"
            ")"
        );

        // Construct the ConsiderationItem type string.
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

        // Construct the OrderComponents type string, not including the above.
        bytes memory orderComponentsPartialTypeString = bytes(
            "OrderComponents("
            "address offerer,"
            "address zone,"
            "OfferItem[] offer,"
            "ConsiderationItem[] consideration,"
            "uint8 orderType,"
            "uint256 startTime,"
            "uint256 endTime,"
            "bytes32 zoneHash,"
            "uint256 salt,"
            "bytes32 conduitKey,"
            "uint256 counter"
            ")"
        );

        // Return the combined string.
        return
            bytes.concat(
                considerationItemTypeString,
                offerItemTypeString,
                orderComponentsPartialTypeString
            );
    }
}
