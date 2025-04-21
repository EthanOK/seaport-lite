// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

error InvalidSignature();

error InvalidBulkOrder(bytes32 orderHash);

event BulkOrderHash(bytes32 indexed orderHash, bytes32[] proof, bytes32 root);
