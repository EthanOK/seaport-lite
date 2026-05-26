// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {
    Counter_blockhash_shift,
    OneWord,
    TwoWords
} from "./ConsiderationConstants.sol";

/**
 * @notice Per-offerer counter used when deriving order hashes and invalidating signatures.
 * @dev Matches Seaport 1.5 `CounterManager`: `incrementCounter` adds a quasi-random delta
 *      (previous blockhash) to the stored counter so bulk cancellation cannot be brute-forced.
 */
contract CounterManager {
    event CounterIncremented(uint256 newCounter, address indexed offerer);
    mapping(address => uint256) private _counters;

    function getCounter(
        address offerer
    ) external view returns (uint256 counter) {
        counter = _getCounter(offerer);
    }

    function incrementCounter() external returns (uint256 newCounter) {
        newCounter = _incrementCounter();
    }

    function _getCounter(
        address offerer
    ) internal view returns (uint256 currentCounter) {
        currentCounter = _counters[offerer];
    }

    function _incrementCounter() internal returns (uint256 newCounter) {
        assembly {
            let quasiRandomNumber := shr(
                Counter_blockhash_shift,
                blockhash(sub(number(), 1))
            )
            mstore(0, caller())
            mstore(OneWord, _counters.slot)
            let storagePointer := keccak256(0, TwoWords)
            newCounter := add(quasiRandomNumber, sload(storagePointer))
            sstore(storagePointer, newCounter)
        }

        emit CounterIncremented(newCounter, msg.sender);
    }
}
