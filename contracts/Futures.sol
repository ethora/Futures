pragma solidity ^0.4.18;

import "zeppelin-solidity/contracts/ownership/Ownable.sol";

contract Futures is Ownable {

    uint public tick_size; //0.01 ETH
    uint public tick_value; //0.01 ETH
    uint public size; //0.5 BTC
    uint8 public margin; //40%
    uint public expire;
    string public name;
    string public symbol;
    uint8 public decimals;//18
    bool public trade;


    function Futures(string _name, string _symbol, uint _expire, uint _size, uint _tick_size, uint _tick_value, uint8 _margin, uint8 _decimals) 
    public {
        require(_margin <= 100 );

        name = _name;
        symbol = _symbol;

        expire = _expire;
        size = _size;
        tick_size = _tick_size;
        tick_value = _tick_value;
        margin = _margin;
        decimals = _decimals;
        trade = false;
    }

    function () payable public {
        revert();
    }
    
    function getSymbol() public view returns(bytes32 result) {
        string memory _symbol = symbol;
        bytes memory tempEmptyStringTest = bytes(_symbol);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
    
        assembly {
            result := mload(add(_symbol, 32))
        }
    }
    
    function invertTrade() public onlyOwner returns (bool){
        trade = !trade;
        return trade;
    }

}