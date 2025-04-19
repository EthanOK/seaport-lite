// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Consideration} from "./lib/Consideration.sol";

contract SeaportLite is Consideration {
    function _nameString() internal pure virtual override returns (string memory) {
        // Return the name of the contract.
        return "Seaport";
    }
}
