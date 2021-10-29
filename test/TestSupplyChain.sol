// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/SupplyChain.sol";
import "./Actor.sol";

contract TestSupplyChain {
    uint public initialBalance = 2 ether;
    event LOG(string txt, uint sku, address seller);
    event LOG(string txt, address addr);
    event LOG(string txt, bool success);
    event LOG(string txt, uint sku);

    Actor alice;
    Actor bob;
    Actor charlie;
    SupplyChain sc;

    function beforeAll() public {

        alice = new Actor();
        bob = new Actor();
        charlie = new Actor();
        address(alice).call{value: 200000}("");
        address(bob).call{value: 300000}("");
        address(charlie).call{value: 400000}("");

    }
    function beforeEach() public {
         sc =  new SupplyChain();

    }
    // Test for failing conditions in this contracts:
    // https://truffleframework.com/tutorials/testing-for-throws-in-solidity-tests

    function test_addItem_success() public payable{
        bool success = alice.addItem(address(sc),"item", 1000);

        uint skuCount = SupplyChain(sc).skuCount();

        Assert.isTrue(success, "Error adding item");
        Assert.equal(1, skuCount, "skuCount should be 1");
    }

    // buyItem
    function test_buyItem_success() public payable{
        alice.addItem(address(sc),"item", 1000);
        bool success = bob.buyItem(address(sc), 0 , 1000);

        Assert.isTrue(success, "Error buying item");
        assertItemBuyer(0, address(bob), 'expected buyer <> actual buyer');
    }

    // test for failure if user does not send enough funds
    function test_buyItem_notEnoughFunds_txShouldFail() public payable{
        alice.addItem(address(sc),"item", 10000);
        bool success = bob.buyItem(address(sc), 0 , 100);

        Assert.isFalse(success, "Tx should fail");
        assertItemBuyer(0, address(0), 'expected buyer not equals to actual buyer (0x000)');
    }

    // test for purchasing an item that is not for Sale
    function test_buyItem_itemNotForSale_txShouldFail() public payable{
        alice.addItem(address(sc),"item", 1000);
        bob.buyItem(address(sc), 0 , 1000);

        bool success = charlie.buyItem(address(sc), 0 , 1000);

        Assert.isFalse(success, "Charlie should not be able to buy the item");
        assertItemBuyer(0, address(bob), 'expected buyer not equals to actual buyer');
    }


    // shipItem
    function test_shipItem_success() public payable{
        alice.addItem(address(sc),"item", 1000);
        bob.buyItem(address(sc), 0 , 1000);

        bool success = alice.shipItem(address(sc), 0);

        Assert.isTrue(success, "Error shipping item");
        assertItemStatus(0, 2, 'Item state should be Shipped');
    }
    // test for calls that are made by not the seller
    function test_shipItem_shippedNotBySeller_shouldFail() public payable{
        alice.addItem(address(sc),"item", 1000);
        bob.buyItem(address(sc), 0 , 1000);

        bool success = bob.shipItem(address(sc), 0);

        Assert.isFalse(success, "Error shipping item");
        assertItemStatus(0, 1, 'Item state should be Sold');
    }
    // test for trying to ship an item that is not marked Sold
    function test_shipItem_itemNotSold_shouldFail() public payable{
        alice.addItem(address(sc),"item", 1000);

        bool success = alice.shipItem(address(sc), 0);

        Assert.isFalse(success, "Error shipping item");
        assertItemStatus(0, 0, 'Item state should be ForSale');
    }

    // receiveItem
    function test_receiveItem_success() public payable{
        alice.addItem(address(sc),"item", 1000);
        bob.buyItem(address(sc), 0 , 1000);
        alice.shipItem(address(sc), 0);

        bool success = bob.receiveItem(address(sc), 0);

        Assert.isTrue(success, "Error buying item");
        assertItemStatus(0, 3, 'Item state should be Received');
    }
    // test calling the function from an address that is not the buyer
    function test_receiveItem_receivedNotByBuyer_txShouldFail() public payable{
        alice.addItem(address(sc),"item", 1000);
        bob.buyItem(address(sc), 0 , 1000);
        alice.shipItem(address(sc), 0);

        bool success = alice.receiveItem(address(sc), 0);

        Assert.isFalse(success, "Alice cannot receive the item");
        assertItemStatus(0, 2, 'Item state should be Shipped');
    }
    // test calling the function on an item not marked Shipped
    function test_receiveItem_itemNotShipped_txShouldFail() public payable{
        alice.addItem(address(sc),"item", 1000);
        bob.buyItem(address(sc), 0 , 1000);

        bool success = bob.receiveItem(address(sc), 0);

        Assert.isFalse(success, "Item state is should be sold");
        assertItemStatus(0, 1, 'Item state should be Sold');
    }



    function assertItemBuyer(uint _sku, address _expectedBuyer, string memory _errorMessage) internal   {
        (string memory name, uint sku, uint price, uint state, address seller, address buyer) = SupplyChain(sc).fetchItem(_sku);
        emit LOG("_expectedBuyer:", _expectedBuyer);
        emit LOG("buyer         :", buyer);
        Assert.equal(_expectedBuyer, buyer, _errorMessage);
    }

    function assertItemStatus(uint _sku, uint _expectedState, string memory _errorMessage) internal   {
        (string memory name, uint sku, uint price, uint state, address seller, address buyer) = SupplyChain(sc).fetchItem(_sku);
        emit LOG("_expectedState:", _expectedState);
        emit LOG("state         :", state);
        Assert.equal(_expectedState, state, _errorMessage);
    }

    fallback() external payable { }
}
