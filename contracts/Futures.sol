pragma solidity ^0.4.17;

import "zeppelin-solidity/contracts/token/BasicToken.sol";
import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "./EthOraAPI.sol";

contract Futures is BasicToken, Ownable {

    uint public tick_size; //0.01 ETH
    uint public tick_value; //0.01 ETH
    uint public size; //0.5 BTC
    uint public margin; //40%
    address public addressTicker;//0x9d27be4ab27f1d498b3aee4b3cbed2b4d9d2b485
    uint public created;
    uint public expire;
    string public name;
    string public symbol;
    uint8 public decimals;//12
    bool public trade;
    
    uint last;
    uint high;
    uint low;
    uint settlement;    
    
    function Futures(string _name, string _symbol, address _addressTicker, uint _expire, 
                    uint _size, uint _tick_size, uint _tick_value, uint _margin, uint8 _decimals) 
    public {
        require(_margin <= uint(100).mul(uint(10)**_decimals));

        name = _name;
        symbol = _symbol;
        addressTicker = _addressTicker;

        expire = _expire;
        created = now;
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
    
    function setCheckpoint(uint _value) public onlyOwner returns(bool){

        require(uint(_value).mul(size).div(uint(10)**decimals) >= tick_size);
    

        uint _v = ((uint(_value).mul(size).div(uint(10)**decimals)) % tick_size) < tick_size.div(2) ? 
                    (uint(_value).mul(size).div(uint(10)**decimals)) - ((uint(_value).mul(size).div(uint(10)**decimals)) % tick_size)  :
                    (uint(_value).mul(size).div(uint(10)**decimals)) - ((uint(_value).mul(size).div(uint(10)**decimals)) % tick_size) + tick_size;
        

        return true;
    }
    
    function getCheckpoint() public view returns(uint, uint, uint, uint)
    {
        return (last, high, low, settlement);
    }
    
    function getLast() public view returns(uint)
    {
        return last;
    }
    
    function invertTrade() public onlyOwner returns (bool){
        trade = !trade;
        return trade;
    }
    
    function setTicker(address _address) public onlyOwner returns (bool){
        addressTicker = _address;
        return true;
    }
    
    function setMargin(uint8 _margin) public onlyOwner returns (bool){
        margin = _margin;
        return true;
    }    
    
    function round(uint _size, uint _price) public view returns (uint){
        return ((_price.mul(_size).div(uint(10)**decimals)) % tick_size) < tick_size.div(2) ? 
                            (_price.mul(_size).div(uint(10)**decimals)) - ((_price.mul(_size).div(uint(10)**decimals)) % tick_size)  :
                            (_price.mul(_size).div(uint(10)**decimals)) - ((_price.mul(_size).div(uint(10)**decimals)) % tick_size) + tick_size;        
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
    
    function generateTokens(address _owner, uint _amount) public onlyOwner returns (bool) {
        require(_owner != address(0));
        balances[_owner] = balances[_owner].add(_amount);
        Transfer(0, _owner, _amount);
        return true;
    }
    
}