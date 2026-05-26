// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { CustomBulkSeaport } from "../src/CustomBulkSeaport.sol";
import {
    CustomOrder,
    CustomOrderComponents
} from "../src/variants/CustomConsiderationStructs.sol";
import { CustomBulkOrderTypeHashHelp } from "../src/variants/CustomBulkOrderTypeHashHelp.sol";
import {
    CustomBulkOrder_Typehash_Height_One,
    CustomOrderComponents_TYPEHASH
} from "../src/variants/CustomConsiderationConstants.sol";

contract CustomBulkSeaportTest is Test {
    address internal constant EXPECTED_OFFERER =
        0x64c21F01dDFAaA90f55042428C6E22FB5aE10890;

    address internal constant CUSTOM_BULK_DEPLOY =
        0x00000000000000000000000000000000000000DE;

    CustomBulkSeaport public seaport;

    struct SignedOrderFixture {
        CustomOrderComponents components;
        bytes signature;
    }

    function setUp() public {
        vm.chainId(11_155_111);
        deployCodeTo("CustomBulkSeaport.sol:CustomBulkSeaport", CUSTOM_BULK_DEPLOY);
        seaport = CustomBulkSeaport(CUSTOM_BULK_DEPLOY);
    }

    function test_eip712Domain() public view {
        (
            ,
            string memory name,
            string memory version,
            ,
            address verifyingContract,
            ,

        ) = seaport.eip712Domain();

        assertEq(name, "CustomBulkSeaport");
        assertEq(version, "1.0");
        assertEq(verifyingContract, CUSTOM_BULK_DEPLOY);
    }

    function test_orderTypehashConstant() public pure {
        assertEq(
            bytes32(CustomOrderComponents_TYPEHASH),
            0xc9aa3ae950bc4b382214c57b9b3ccec5119b20cfdadc73dd64c74f915eec249a
        );
    }

    function test_validateSignature_single() public {
        SignedOrderFixture memory f = _ffiExport("single");
        assertTrue(seaport.validateOrder(CustomOrder(f.components, f.signature)));
    }

    function test_validateSignature_bulk() public {
        SignedOrderFixture memory f = _ffiExport("bulk");
        assertTrue(seaport.validateOrder(CustomOrder(f.components, f.signature)));
    }

    function test_getBulkOrderTypeHashs_heightOne() public {
        bytes32[] memory hashes = (new CustomBulkOrderTypeHashHelp())
            .getBulkOrderTypeHashs();
        assertEq(hashes[0], bytes32(CustomBulkOrder_Typehash_Height_One));
    }

    function _ffiExport(
        string memory mode
    ) internal returns (SignedOrderFixture memory f) {
        string[] memory inputs = new string[](5);
        inputs[0] = "npx";
        inputs[1] = "tsx";
        inputs[2] = "test/helpers/custom-bulk-seaport-test.ts";
        inputs[3] = "export";
        inputs[4] = mode;

        bytes memory encoded = vm.ffi(inputs);
        (f.components, f.signature) = abi.decode(
            encoded,
            (CustomOrderComponents, bytes)
        );
        assertEq(f.components.offerer, EXPECTED_OFFERER);
    }
}
