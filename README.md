# opensea order

## sign bulk order 

[signbulkorder SDK](https://github.com/EthanOK/signbulkorder-sdk)

## sign opensea order with EIP712

```javascript
const EIP712OpenSeaMessage = async (signer, chainId) => {
  const domainData = {
    name: "Seaport",
    version: "1.5",
    chainId: chainId,
    verifyingContract: "0x00000000000000ADc04C56Bf30aC9d3c0aAF14dC",
  };

  const types = {
    OrderComponents: [
      {
        name: "offerer",
        type: "address",
      },
      {
        name: "zone",
        type: "address",
      },
      {
        name: "offer",
        type: "OfferItem[]",
      },
      {
        name: "consideration",
        type: "ConsiderationItem[]",
      },
      {
        name: "orderType",
        type: "uint8",
      },
      {
        name: "startTime",
        type: "uint256",
      },
      {
        name: "endTime",
        type: "uint256",
      },
      {
        name: "zoneHash",
        type: "bytes32",
      },
      {
        name: "salt",
        type: "uint256",
      },
      {
        name: "conduitKey",
        type: "bytes32",
      },
      {
        name: "counter",
        type: "uint256",
      },
    ],
    OfferItem: [
      {
        name: "itemType",
        type: "uint8",
      },
      {
        name: "token",
        type: "address",
      },
      {
        name: "identifierOrCriteria",
        type: "uint256",
      },
      {
        name: "startAmount",
        type: "uint256",
      },
      {
        name: "endAmount",
        type: "uint256",
      },
    ],
    ConsiderationItem: [
      {
        name: "itemType",
        type: "uint8",
      },
      {
        name: "token",
        type: "address",
      },
      {
        name: "identifierOrCriteria",
        type: "uint256",
      },
      {
        name: "startAmount",
        type: "uint256",
      },
      {
        name: "endAmount",
        type: "uint256",
      },
      {
        name: "recipient",
        type: "address",
      },
    ],
  };

  let message = {
    offerer: "0x6278A1E803A76796a3A1f7F6344fE874ebfe94B2",
    zone: "0x004C00500000aD104D7DBd00e3ae0A5C00560C00",
    offer: [
      {
        itemType: 2,
        token: "0x97f236E644db7Be9B8308525e6506E4B3304dA7B",
        identifierOrCriteria: BigNumber.from("111"),
        startAmount: BigNumber.from("1"),
        endAmount: BigNumber.from("1"),
      },
    ],
    consideration: [
      {
        itemType: 0,
        token: "0x0000000000000000000000000000000000000000",
        identifierOrCriteria: BigNumber.from("0"),
        startAmount: BigNumber.from("1082250000000000000"),
        endAmount: BigNumber.from("1082250000000000000"),
        recipient: "0x6278A1E803A76796a3A1f7F6344fE874ebfe94B2",
      },
      {
        itemType: 0,
        token: "0x0000000000000000000000000000000000000000",
        identifierOrCriteria: BigNumber.from("0"),
        startAmount: BigNumber.from("27750000000000000"),
        endAmount: BigNumber.from("27750000000000000"),
        recipient: "0x0000a26b00c1F0DF003000390027140000fAa719",
      },
    ],
    orderType: 0,
    startTime: BigNumber.from("1686193412"),
    endTime: BigNumber.from("1688785412"),
    zoneHash:
      "0x0000000000000000000000000000000000000000000000000000000000000000",
    salt: BigNumber.from(
      "24446860302761739304752683030156737591518664810215442929818227897836383814680"
    ),
    conduitKey:
      "0x0000007b02230091a7ed01230072f7006a004d60a8d4e71d599b8104250f0000",
    counter: BigNumber.from("0"),
  };

  try {
    const orderSignature = await signer._signTypedData(
      domainData,
      types,
      message
    );

    console.log("orderSignature:" + orderSignature);

    let orderHash = _TypedDataEncoder.from(types).hash(message);

    console.log("orderHash: " + orderHash);
  } catch (error) {}
};
```

## verify Signature in contract

```solidity
    function test_validateSignature() public view {
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
            recipient: payable(address(0x6278A1E803A76796a3A1f7F6344fE874ebfe94B2))
        });
        consideration[1] = ConsiderationItem({
            itemType: ItemType.NATIVE,
            token: address(0),
            identifierOrCriteria: 0,
            startAmount: 27750000000000000,
            endAmount: 27750000000000000,
            recipient: payable(address(0x0000a26b00c1F0DF003000390027140000fAa719))
        });

        OrderComponents memory orderParameters = OrderComponents({
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

        bytes memory signature =
            hex"30821bc4aefea2829e00d4dcce28c305c93c1d1ef261867ed7279fa9fca6f26548f9ac6263d68a7ea7a530987a7622d5e30ced13be2a3877fdb7f6d3ed37dee91c";

        bytes32 orderhash = seaportLite.getOrderStructHash(orderParameters);
        assertEq(orderhash, 0x93615616691158f9686e276600f0cc591b902c161aae970f324f908b001d7b25);

        bool isValid = seaportLite.validateSignature(Order(orderParameters, signature));
        assertEq(isValid, true);

        bytes memory signature_invalid =
            hex"89f879a6ff075f1342fb313926c36ec3e5c59fe4b369052a865a4858983f410c5b20ec90e59807db86c07a29cf9c2f1475817048429498f48251990957a2cec51b";
        isValid = seaportLite.validateSignature(Order(orderParameters, signature_invalid));
        assertEq(isValid, false);
    }
```
