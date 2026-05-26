// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { CustomConsiderationBase } from "./CustomConsiderationBase.sol";
import {
    CustomOrderComponents,
    CustomOfferItem,
    CustomConsiderationItem,
    CustomOrder
} from "./CustomConsiderationStructs.sol";
import { CounterManager } from "../lib/CounterManager.sol";
import { CustomVerifiers } from "./CustomVerifiers.sol";
import { EIP712 } from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {
    SignatureChecker
} from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

/// @notice Signature verification for OrderComponents without zone / zoneHash / conduitKey.
contract CustomConsideration is
    EIP712,
    CustomConsiderationBase,
    CounterManager,
    CustomVerifiers
{
    bytes32 internal immutable _NAME_HASH;
    bytes32 internal immutable _VERSION_HASH;
    bytes32 internal immutable _EIP_712_DOMAIN_TYPEHASH;
    bytes32 internal immutable _OFFER_ITEM_TYPEHASH;
    bytes32 internal immutable _CONSIDERATION_ITEM_TYPEHASH;
    bytes32 internal immutable _ORDER_TYPEHASH;

    constructor() EIP712(_nameString(), _versionString()) {
        (
            _NAME_HASH,
            _VERSION_HASH,
            _EIP_712_DOMAIN_TYPEHASH,
            _OFFER_ITEM_TYPEHASH,
            _CONSIDERATION_ITEM_TYPEHASH,
            _ORDER_TYPEHASH
        ) = _deriveTypehashes();
    }

    function getOrderStructHash(
        CustomOrderComponents calldata order
    ) public view returns (bytes32) {
        return hashOrderComponents(order);
    }

    function validateOrder(
        CustomOrder calldata order
    ) external view returns (bool) {
        require(
            order.parameters.startTime <= block.timestamp &&
                order.parameters.endTime >= block.timestamp,
            "Order expired"
        );
        return validateSignature(order);
    }

    function validateSignature(
        CustomOrder calldata order
    ) public view returns (bool) {
        bytes32 orderHash = hashOrderComponents(order.parameters);
        bytes memory signature = order.signature;
        uint256 signatureLength = signature.length;

        if (_isValidBulkOrderSize(signatureLength)) {
            orderHash = _computeBulkOrderProof(signature, orderHash);
        }

        bytes32 digest = getDigest(orderHash);

        if (signature.length == 64) {
            signature = normalizeSignature(signature);
        }

        return
            SignatureChecker.isValidSignatureNow(
                order.parameters.offerer,
                digest,
                signature
            );
    }

    function getDigest(
        CustomOrderComponents calldata order
    ) internal view returns (bytes32) {
        return _hashTypedDataV4(hashOrderComponents(order));
    }

    function getDigest(bytes32 orderHash) internal view returns (bytes32) {
        return _hashTypedDataV4(orderHash);
    }

    function hashOrderComponents(
        CustomOrderComponents calldata order
    ) internal view returns (bytes32) {
        bytes32[] memory offerHashes = new bytes32[](order.offer.length);
        for (uint256 i = 0; i < order.offer.length; i++) {
            offerHashes[i] = hashOfferItem(order.offer[i]);
        }
        bytes32[] memory considerationHashes = new bytes32[](
            order.consideration.length
        );
        for (uint256 i = 0; i < order.consideration.length; i++) {
            considerationHashes[i] = hashConsiderationItem(
                order.consideration[i]
            );
        }
        uint256 counter = _getCounter(order.offerer);
        return
            keccak256(
                abi.encode(
                    _ORDER_TYPEHASH,
                    order.offerer,
                    keccak256(abi.encodePacked(offerHashes)),
                    keccak256(abi.encodePacked(considerationHashes)),
                    order.orderType,
                    order.startTime,
                    order.endTime,
                    order.salt,
                    counter
                )
            );
    }

    function hashOfferItem(
        CustomOfferItem calldata offerItem
    ) internal view returns (bytes32) {
        return keccak256(abi.encode(_OFFER_ITEM_TYPEHASH, offerItem));
    }

    function hashConsiderationItem(
        CustomConsiderationItem memory considerationItem
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(_CONSIDERATION_ITEM_TYPEHASH, considerationItem)
            );
    }

    function normalizeSignature(
        bytes memory signature
    ) internal pure returns (bytes memory) {
        bytes32 r;
        bytes32 vs;
        assembly ("memory-safe") {
            r := mload(add(signature, 0x20))
            vs := mload(add(signature, 0x40))
        }
        bytes32 s = vs &
            bytes32(
                0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
            );
        uint8 v = uint8((uint256(vs) >> 255)) + 27;
        return abi.encodePacked(r, s, v);
    }

    function getRoot(
        uint256 key,
        bytes32 leaf,
        bytes32[] memory proof
    ) public pure returns (bytes32) {
        return _getRoot(key, leaf, proof);
    }
}
