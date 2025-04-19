// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ConsiderationBase} from "./ConsiderationBase.sol";
import {OrderComponents, OfferItem, ConsiderationItem, Order} from "./ConsiderationStructs.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {SignatureChecker} from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

contract Consideration is EIP712, ConsiderationBase {
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

    function getOrderStructHash(OrderComponents calldata order) public view returns (bytes32) {
        bytes32 orderHash = hashOrderComponents(order);
        return orderHash;
    }

    function validateSignature(Order calldata order) external view returns (bool) {
        bytes32 digest = getDigest(order.parameters);
        bytes memory signature = order.signature;
        if (signature.length == 64) {
            signature = normalizeSignature(signature);
        }

        bool isValid = SignatureChecker.isValidSignatureNow(order.parameters.offerer, digest, signature);
        return isValid;
    }

    function getDigest(OrderComponents calldata order) internal view returns (bytes32) {
        bytes32 orderHash = hashOrderComponents(order);

        return _hashTypedDataV4(orderHash);
    }

    // calculate OrderComponents's structHash
    function hashOrderComponents(OrderComponents calldata order) internal view returns (bytes32) {
        bytes32[] memory offerHashes = new bytes32[](order.offer.length);
        for (uint256 i = 0; i < order.offer.length; i++) {
            offerHashes[i] = hashOfferItem(order.offer[i]);
        }
        bytes32[] memory considerationHashes = new bytes32[](order.consideration.length);
        for (uint256 i = 0; i < order.consideration.length; i++) {
            considerationHashes[i] = hashConsiderationItem(order.consideration[i]);
        }
        return keccak256(
            abi.encode(
                _ORDER_TYPEHASH,
                order.offerer,
                order.zone,
                keccak256(abi.encodePacked(offerHashes)), // OfferItem[] 哈希
                keccak256(abi.encodePacked(considerationHashes)), // ConsiderationItem[] 哈希
                order.orderType,
                order.startTime,
                order.endTime,
                order.zoneHash,
                order.salt,
                order.conduitKey,
                order.counter
            )
        );
    }

    // calculate OfferItem's structHash
    function hashOfferItem(OfferItem calldata offerItem) internal view returns (bytes32) {
        return keccak256(
            abi.encode(
                _OFFER_ITEM_TYPEHASH,
                offerItem.itemType,
                offerItem.token,
                offerItem.identifierOrCriteria,
                offerItem.startAmount,
                offerItem.endAmount
            )
        );
    }

    // calculate ConsiderationItem's structHash

    function hashConsiderationItem(ConsiderationItem memory item) internal view returns (bytes32) {
        return keccak256(
            abi.encode(
                _CONSIDERATION_ITEM_TYPEHASH,
                item.itemType,
                item.token,
                item.identifierOrCriteria,
                item.startAmount,
                item.endAmount,
                item.recipient
            )
        );
    }

    /**
     * @dev Converts a 64-byte compact signature (ERC-2098 format) to a 65-byte standard signature
     * @param signature The input signature (either 64 or 65 bytes)
     * @return The standardized 65-byte signature
     */
    function normalizeSignature(bytes memory signature) internal pure returns (bytes memory) {
        // ERC-2098 compact format detected (64 bytes) - convert to standard 65-byte format
        bytes32 r;
        bytes32 vs; // vs contains both v and s components

        // Extract r and vs using assembly for efficiency
        assembly ("memory-safe") {
            // First 32 bytes of signature = r
            r := mload(add(signature, 0x20))
            // Next 32 bytes = vs (v and s combined)
            vs := mload(add(signature, 0x40))
        }

        // Extract s from vs (clear the most significant bit)
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);

        // Extract v from vs (most significant bit + 27)
        uint8 v = uint8((uint256(vs) >> 255)) + 27;

        // Reconstruct 65-byte signature (r + s + v)
        return abi.encodePacked(r, s, v);
    }
}
