pragma solidity ^0.4.17;

import "zeppelin-solidity/contracts/token/BasicToken.sol";
import "zeppelin-solidity/contracts/ownership/Ownable.sol";

contract Futures is BasicToken, Ownable {
    
    uint public last;
    uint public high;
    uint public low;
    uint public settlement;
    uint public tick_size;
    uint public tick_value;
    uint public size;
    uint8 public margin;
    address public addressTicker;//0xfD12b06273c8F96Df27471Bf49F173c5f0B99ea6
    uint public created;
    uint public expire;
    string public name;
    string public symbol;
    uint8 public decimals;
    
    function Futures(string _name, string _symbol, address _addressTicker, uint _expire, 
                    uint _value, uint _size, uint _tick_size, uint _tick_value, uint8 _margin) 
    public {
        name = _name;
        symbol = _symbol;
        addressTicker = _addressTicker;
        expire = _expire;
        created = now;
        last = _value;
        settlement = _value;
        low = _value - (_value / 100 * _margin);
        high = _value + (_value / 100 * _margin);
        size = _size;
        tick_size = _tick_size;
        tick_value = _tick_value;
        margin = _margin;
    }

    function () payable public {
        revert();
    }
    
    function setLast(uint _value) public onlyOwner returns (bool){
        last = _value;
        return true;
    }
    
    function setHigh(uint _value) public onlyOwner returns (bool){
        high = _value;
        return true;
    }

    function setLow(uint _value) public onlyOwner returns (bool){
        low = _value;
        return true;
    }
    
    function setSettlement(uint _value) public onlyOwner returns (bool){
        settlement = _value;
        return true;
    }

    function setTicker(address _address) public onlyOwner returns (bool){
        addressTicker = _address;
        return true;
    }
    
    function setMargin(uint8 _margin) public onlyOwner returns (bool){
        margin = _margin;
        return true;
    }    

    function transfer(address _to, uint256 _value) public onlyOwner returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public onlyOwner returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(_from, _to, _value);
        return true;
    }
}