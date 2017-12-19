pragma solidity ^0.4.17;

import "zeppelin-solidity/contracts/token/BasicToken.sol";
import "zeppelin-solidity/contracts/ownership/Ownable.sol";

contract Futures is BasicToken, Ownable {

    uint public tick_size; //0.01 ETH
    uint public tick_value; //0.01 ETH
    uint public size; //0.5 BTC
    uint8 public margin; //40%
    address public addressTicker;//0xfD12b06273c8F96Df27471Bf49F173c5f0B99ea6
    uint public created;
    uint public expire;
    string public name;
    string public symbol;
    uint8 public decimals;//12
    bool public trade;
    
    Checkpoint[] internal checkpoints;
    
    struct  Checkpoint {
        uint Block;
        uint datetime;
        uint last;
        uint high;
        uint low;
        uint settlement;
    }    
    
    function Futures(string _name, string _symbol, address _addressTicker, uint _expire, 
                    uint _value, uint _size, uint _tick_size, uint _tick_value, uint8 _margin, uint8 _decimals) 
    public {
        require(_margin <= 100);
        require(_value.mul(_size).div(uint(10)**_decimals) >= _tick_size);
        name = _name;
        symbol = _symbol;
        addressTicker = _addressTicker;
        expire = _expire;
        created = now;
        
        uint _v = ((_value.mul(_size).div(uint(10)**_decimals)) % _tick_size) < _tick_size.div(2) ? 
                    (_value.mul(_size).div(uint(10)**_decimals)) - ((_value.mul(_size).div(uint(10)**_decimals)) % _tick_size)  :
                    (_value.mul(_size).div(uint(10)**_decimals)) - ((_value.mul(_size).div(uint(10)**_decimals)) % _tick_size) + _tick_size;
        
        checkpoints.push(Checkpoint({Block: block.number, 
                                    datetime: created, 
                                    last: _v,// _value.mul(_size).div(uint(10)**_decimals), 
                                    settlement: _v, //_value.mul(_size).div(uint(10)**_decimals), 
                                    low:  _v.mul(100 - (_margin / 2)).div(100), //_v.sub(_v.div(200).mul(_margin)).mul(_size).div(uint(10)**_decimals), 
                                    high: _v.mul(100 + (_margin / 2)).div(100) //_v.add(_v.div(200).mul(_margin)).mul(_size).div(uint(10)**_decimals)
                                    }));

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
    
    function getCheckpoint() public view returns(uint, uint, uint, uint)
    {
        require(checkpoints.length > 0);
        return (checkpoints[checkpoints.length-1].last, 
                checkpoints[checkpoints.length-1].high, 
                checkpoints[checkpoints.length-1].low, 
                checkpoints[checkpoints.length-1].settlement);
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