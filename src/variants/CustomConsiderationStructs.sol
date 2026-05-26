// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { OrderType, ItemType } from "../lib/ConsiderationEnums.sol";

/// @notice Same EIP-712 type name `OrderComponents`, fewer fields (no zone / zoneHash / conduitKey).
struct CustomOrder {
    CustomOrderComponents parameters;
    bytes signature;
}

struct CustomOrderComponents {
    address offerer;
    CustomOfferItem[] offer;
    CustomConsiderationItem[] consideration;
    OrderType orderType;
    uint256 startTime;
    uint256 endTime;
    uint256 salt;
    uint256 counter;
}

struct CustomOfferItem {
    ItemType itemType;
    address token;
    uint256 identifierOrCriteria;
    uint256 startAmount;
    uint256 endAmount;
}

struct CustomConsiderationItem {
    ItemType itemType;
    address token;
    uint256 identifierOrCriteria;
    uint256 startAmount;
    uint256 endAmount;
    address payable recipient;
}
