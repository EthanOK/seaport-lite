// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Test, console } from "forge-std/Test.sol";
import { SeaportLite } from "../src/SeaportLite.sol";
import {
    Order,
    OrderComponents,
    OfferItem,
    ConsiderationItem,
    OrderType,
    ItemType
} from "../src/lib/ConsiderationBase.sol";
import { BulkOrderTypeHashHelp } from "../src/lib/BulkOrderTypeHashHelp.sol";
import {
    BulkOrder_Typehash_Height_One
} from "../src/lib/ConsiderationConstants.sol";

contract SeaportLiteTest is Test {
    SeaportLite public seaportLite;
    BulkOrderTypeHashHelp public bulkOrderTypeHash;

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

    function test_validateSignature() public view {
        OrderComponents memory orderComponents = getOrderComponents();

        bytes
            memory signature = hex"30821bc4aefea2829e00d4dcce28c305c93c1d1ef261867ed7279fa9fca6f26548f9ac6263d68a7ea7a530987a7622d5e30ced13be2a3877fdb7f6d3ed37dee91c";

        bytes32 orderhash = seaportLite.getOrderStructHash(orderComponents);
        assertEq(
            orderhash,
            0x93615616691158f9686e276600f0cc591b902c161aae970f324f908b001d7b25
        );

        bool isValid = seaportLite.validateSignature(
            Order(orderComponents, signature)
        );
        assertEq(isValid, true);

        bytes
            memory signature_invalid = hex"89f879a6ff075f1342fb313926c36ec3e5c59fe4b369052a865a4858983f410c5b20ec90e59807db86c07a29cf9c2f1475817048429498f48251990957a2cec51b";

        isValid = seaportLite.validateSignature(
            Order(orderComponents, signature_invalid)
        );
        assertEq(isValid, false);
    }

    function test_validateSignature_BulkOrder() public view {
        OrderComponents memory orderComponents = getOrderComponents();

        bytes
            memory signature = hex"fd37e871adc6bf892ac52a480f4554dde1f70ab23b7061bcbaed88b535f0efdc54d2ebf303f002d68a1b6da1050360fb233f2ef6c6e0dcb7492924a181db667d00000006bfdd4fee487c47799fd9aa57225e03268298d2983ff74cbab178665fab33ea";

        bool isValid = seaportLite.validateSignature(
            Order(orderComponents, signature)
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

    function getOrderComponents()
        internal
        pure
        returns (OrderComponents memory)
    {
        OfferItem[] memory offer = new OfferItem[](1);
        offer[0] = OfferItem({
            itemType: ItemType.ERC721,
            token: 0x97f236E644db7Be9B8308525e6506E4B3304dA7B,
            identifierOrCriteria: 111,
            startAmount: 1,
            endAmount: 1
        });

        ConsiderationItem[] memory consideration = new ConsiderationItem[](2);
        consideration[0] = ConsiderationItem({
            itemType: ItemType.NATIVE,
            token: address(0),
            identifierOrCriteria: 0,
            startAmount: 1082250000000000000,
            endAmount: 1082250000000000000,
            recipient: payable(
                address(0x6278A1E803A76796a3A1f7F6344fE874ebfe94B2)
            )
        });
        consideration[1] = ConsiderationItem({
            itemType: ItemType.NATIVE,
            token: address(0),
            identifierOrCriteria: 0,
            startAmount: 27750000000000000,
            endAmount: 27750000000000000,
            recipient: payable(
                address(0x0000a26b00c1F0DF003000390027140000fAa719)
            )
        });

        OrderComponents memory orderComponents = OrderComponents({
            offerer: 0x6278A1E803A76796a3A1f7F6344fE874ebfe94B2,
            zone: 0x004C00500000aD104D7DBd00e3ae0A5C00560C00,
            offer: offer,
            consideration: consideration,
            orderType: OrderType.FULL_OPEN,
            startTime: 1686193412,
            endTime: 1688785412,
            zoneHash: bytes32(0),
            salt: 24446860302761739304752683030156737591518664810215442929818227897836383814680,
            conduitKey: 0x0000007b02230091a7ed01230072f7006a004d60a8d4e71d599b8104250f0000,
            counter: 0
        });

        return orderComponents;
    }

    function test_getBulkOrderRoot() public view {
        // OrderComponents memory orderComponents = getOrderComponents();
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
        proof[0]=0x519d6c3dbe7fc17053e1a4ab6f1919797ab73fbd9cea67e4f52ec4227ffc4ec9;
        bytes32 root_0 = seaportLite.getRoot(key, leaf, proof);
       assertEq(root_0, root_1);
    }
}
