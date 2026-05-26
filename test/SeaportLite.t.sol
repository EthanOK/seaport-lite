// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Test, console } from "forge-std/Test.sol";
import { SeaportLite } from "../src/SeaportLite.sol";
import { Order, OrderComponents } from "../src/lib/ConsiderationBase.sol";
import { BulkOrderTypeHashHelp } from "../src/lib/BulkOrderTypeHashHelp.sol";
import {
    BulkOrder_Typehash_Height_One
} from "../src/lib/ConsiderationConstants.sol";
import { InvalidCounter } from "../src/lib/ConsiderationEventsAndErrors.sol";

contract SeaportLiteTest is Test {
    /// Must match Wallet(PRIVATE_KEY) in .env — see test/seaport-test.ts
    address internal constant EXPECTED_OFFERER =
        0x64c21F01dDFAaA90f55042428C6E22FB5aE10890;

    SeaportLite public seaportLite;
    BulkOrderTypeHashHelp public bulkOrderTypeHash;

    struct SignedOrderFixture {
        OrderComponents components;
        bytes signature;
    }

    function setUp() public {
        bulkOrderTypeHash = new BulkOrderTypeHashHelp();

        vm.chainId(11155111);

        address flags = address(0x00000000000000ADc04C56Bf30aC9d3c0aAF14dC);

        deployCodeTo("SeaportLite.sol:SeaportLite", flags);

        seaportLite = SeaportLite(flags);
    }

    function test_eip712Domain() public view {
        (
            ,
            string memory name,
            string memory version,
            ,
            address verifyingContract,
            ,

        ) = seaportLite.eip712Domain();

        assertEq(name, "Seaport");
        assertEq(version, "1.5");
        assertEq(verifyingContract, address(seaportLite));
    }

    function test_getCounter_defaultsToZero() public view {
        assertEq(seaportLite.getCounter(EXPECTED_OFFERER), 0);
    }

    function test_validateSignature() public {
        SignedOrderFixture memory fixture = getSignedOrder("single");

        bool isValid = seaportLite.validateOrder(
            Order(fixture.components, fixture.signature)
        );
        assertEq(isValid, true);
    }

    function test_incrementCounter_invalidatesPriorOrders() public {
        SignedOrderFixture memory fixture = getSignedOrder("single");

        vm.roll(100);
        vm.setBlockhash(99, bytes32(uint256(100) << 128));
        vm.prank(EXPECTED_OFFERER);
        uint256 newCounter = seaportLite.incrementCounter();

        assertEq(newCounter, 100);
        assertEq(seaportLite.getCounter(EXPECTED_OFFERER), 100);

        vm.expectRevert(
            abi.encodeWithSelector(
                InvalidCounter.selector,
                uint256(0),
                uint256(100)
            )
        );
        seaportLite.validateOrder(
            Order(fixture.components, fixture.signature)
        );
    }

    function test_invalidSignature_fails() public {
        SignedOrderFixture memory fixture = getSignedOrder("single");

        bytes
            memory signatureInvalid = hex"89f879a6ff075f1342fb313926c36ec3e5c59fe4b369052a865a4858983f410c5b20ec90e59807db86c07a29cf9c2f1475817048429498f48251990957a2cec51b";

        assertFalse(
            seaportLite.validateSignature(
                Order(fixture.components, signatureInvalid)
            )
        );
    }

    function test_validateSignature_BulkOrder() public {
        SignedOrderFixture memory fixture = getSignedOrder("bulk");

        bool isValid = seaportLite.validateOrder(
            Order(fixture.components, fixture.signature)
        );
        assertEq(isValid, true);
    }

    function test_getBulkOrderTypeHashs() public view {
        bytes32[] memory bulkOrderTypeHashs = bulkOrderTypeHash
            .getBulkOrderTypeHashs();
        assertEq(bulkOrderTypeHashs.length, 24);
        console.log("bulkOrderTypeHashs:");
        for (uint i = 0; i < bulkOrderTypeHashs.length; i++) {
            console.logBytes32(bulkOrderTypeHashs[i]);
        }

        assertEq(bulkOrderTypeHashs[0], bytes32(BulkOrder_Typehash_Height_One));
    }

    /// @dev One FFI call to test/seaport-test.ts — order + signature from same PRIVATE_KEY
    function getSignedOrder(
        string memory mode
    ) internal returns (SignedOrderFixture memory fixture) {
        string[] memory inputs = new string[](5);
        inputs[0] = "npx";
        inputs[1] = "tsx";
        inputs[2] = "test/seaport-test.ts";
        inputs[3] = "export";
        inputs[4] = mode;

        bytes memory encoded = vm.ffi(inputs);
        (fixture.components, fixture.signature) = abi.decode(
            encoded,
            (OrderComponents, bytes)
        );
        assertEq(
            fixture.components.offerer,
            EXPECTED_OFFERER,
            "offerer must match PRIVATE_KEY in .env"
        );
    }

    function test_getBulkOrderRoot() public view {
        uint256 key = 1;
        bytes32 leaf = 0x519d6c3dbe7fc17053e1a4ab6f1919797ab73fbd9cea67e4f52ec4227ffc4ec9;
        bytes32[] memory proof = new bytes32[](2);
        proof[
            0
        ] = 0x770d3d9c422e862698be1991122197ea68ea9e5510c0455ec7ee1951bec88a64;
        proof[
            1
        ] = 0x3115835973f9266a5df1c0b9f81fd6305a00725ed85deba0880a1ad117c72763;

        bytes32 root_1 = seaportLite.getRoot(key, leaf, proof);

        key = 0;
        leaf = 0x770d3d9c422e862698be1991122197ea68ea9e5510c0455ec7ee1951bec88a64;
        proof[
            0
        ] = 0x519d6c3dbe7fc17053e1a4ab6f1919797ab73fbd9cea67e4f52ec4227ffc4ec9;
        bytes32 root_0 = seaportLite.getRoot(key, leaf, proof);
        assertEq(root_0, root_1);
    }
}
