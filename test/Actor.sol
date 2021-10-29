pragma solidity 0.8.9;
import "../contracts/SupplyChain.sol";

contract Actor {
    constructor()  payable{ }

    fallback() external payable {}

    function addItem(address _sc, string memory _item, uint _price) public returns (bool) {
        (bool success, bytes memory returnData) = _sc.call(abi.encodeWithSignature("addItem(string,uint256)", _item, _price));
        return success;
    }

    function buyItem(address _sc, uint _sku, uint price) public payable returns (bool){
        (bool success, bytes memory returnData)  = _sc.call{value: price}(abi.encodeWithSignature("buyItem(uint256)", _sku));
        return success;
    }

    function shipItem(address _sc, uint _sku) public returns (bool){
        (bool success, bytes memory returnData)  = _sc.call(abi.encodeWithSignature("shipItem(uint256)", _sku));
        return success;
    }

    function receiveItem(address _sc, uint _sku) public returns (bool){
        (bool success, bytes memory returnData)  = _sc.call(abi.encodeWithSignature("receiveItem(uint256)", _sku));
        return success;
    }

   /* function fetchItem(address _sc, uint _sku) public payable returns (string memory name, uint sku, uint price, uint state, address seller, address buyer){

        (string memory name, uint sku, uint price, uint state, address seller, address buyer) = SupplyChain(_sc).fetchItem(_sku);
        return ( name,  sku,  price,  state, seller,  buyer);
    }*/
}
