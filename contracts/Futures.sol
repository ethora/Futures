pragma solidity ^0.4.17;

import "zeppelin-solidity/contracts/token/BasicToken.sol";
import "zeppelin-solidity/contracts/ownership/Ownable.sol";

contract Futures is BasicToken, Ownable {

    uint public tick_size; //0.0001
    uint public size; //5 ETH
    uint8 public margin; //40%
    address public addressTicker;//0xfD12b06273c8F96Df27471Bf49F173c5f0B99ea6
    uint public created;
    uint public expire;
    string public name;
    string public symbol;
    uint8 public decimals;//12
    
    Checkpoint[] internal checkpoints;
    
    struct  Checkpoint {
        uint Block;
        uint datetime;
        uint last;
        uint high;
        uint low;
        uint settlement;
        uint tick_value;
    }    
    
    function Futures(string _name, string _symbol, address _addressTicker, uint _expire, 
                    uint _value, uint _size, uint _tick_size, uint8 _margin, uint8 _decimals) 
    public {
        require(_margin <= 100);
        name = _name;
        symbol = _symbol;
        addressTicker = _addressTicker;
        expire = _expire;
        created = now;
        
        checkpoints.push(Checkpoint({Block: block.number, 
                                    datetime: created, 
                                    last: _value.mul(_size), 
                                    tick_value: _tick_size.div(_value).mul(_size), 
                                    settlement: _value.mul(_size), 
                                    low: 0, // _value.sub(_value.div(200).mul(_margin)).mul(_size), 
                                    high: 0 //_value.add(_value.div(200).mul(_margin)).mul(_size)
                                    }));

        size = _size;
        tick_size = _tick_size;
        margin = _margin;
        decimals = _decimals;
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
    
    function getCheckpoint() public view returns(uint, uint, uint, uint, uint)
    {
        require(checkpoints.length > 0);
        return (checkpoints[checkpoints.length-1].last, 
                checkpoints[checkpoints.length-1].high, 
                checkpoints[checkpoints.length-1].low, 
                checkpoints[checkpoints.length-1].settlement, 
                checkpoints[checkpoints.length-1].tick_value);
    }
    
    /*function setLast(uint _value) public onlyOwner returns (bool){
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
    }*/

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