pragma solidity ^0.4.18;

import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "zeppelin-solidity/contracts/ownership/CanReclaimToken.sol";
//import "zeppelin-solidity/contracts/token/StandardToken.sol";
import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "zeppelin-solidity/contracts/math/Math.sol";
import "./FuturesExchToken.sol";
//import "oraclize/ethereum-api/oraclizeAPI.sol";
//import "library/DateTimeAPI.sol";

import "./Controlled.sol";

contract Futures is Ownable, Controlled, CanReclaimToken {//, usingOraclize {

    using SafeMath for uint256;
    using Math for uint256;

    uint public tick_size; //0.01 ETH
    uint public tick_value; //0.01 ETH
    uint public size; // with decimals
    uint8 public margin; //40%
    uint public expire;
    string public name;
    string public symbol;
    string public URL;// for Oraclize json(https://api.coinmarketcap.com/v1/ticker/ethereum/).0.price_btc
    uint8 public decimals;//18
    bool public trade;
    address futuresExch;
    //Checkpoint[] history;
    uint last;
    mapping(bytes32=>bool) validIds;
    mapping(address => Checkpoint[]) balances;

    struct Checkpoint {
        uint dt;
        uint Block;
        int value;
    }
    
    event updatedValue(uint value);
    event newOraclizeQuery(string description);    
    event Transfer(address indexed from, address indexed to, uint256 value);


    function Futures(string _name, string _symbol, uint _expire, uint _size, uint _tick_size, uint _tick_value, uint8 _margin, uint8 _decimals, string url, address _futuresExch) 
    public {
        require(_margin <= 100 );
        require(_futuresExch != address(0));

        name = _name;
        symbol = _symbol;

        expire = _expire;
        size = _size;
        tick_size = _tick_size;
        tick_value = _tick_value;
        margin = _margin;
        decimals = _decimals;
        trade = false;
        URL = url;
        futuresExch = _futuresExch;
        addChanger(_futuresExch);
    }
    
    function() public payable { }

    function balanceOf(address _owner) public view returns (int256 balance) {
        if (balances[_owner].length == 0) return;
        return balances[_owner][balances[_owner].length-1].value;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public onlyChanger returns (bool) {
        require(_to != address(0));
        require(_from != address(0));
        balances[_from].push(Checkpoint({dt: now, Block: block.number, value: balanceOf(_from) - int256(_value)}));
        balances[_to].push(Checkpoint({dt: now, Block: block.number, value: balanceOf(_to) + int256(_value)}));
        Transfer(_from, _to, _value);
        return true;
      }    

    /*function __callback(bytes32 myid, string result) public {
        require(trade);
        require(validIds[myid]);
        require(msg.sender == oraclize_cbAddress());
        
        //roundPrice((base**decimals).mul(base**decimals).div(stringToUint(result)).mul(size).div(base**decimals))
        uint XBTC = roundPrice((uint(10)**decimals).mul(size).div(stringToUint(result)));
        history.push(Checkpoint({dt: now, Block: block.number, value: XBTC}));
        updatedValue(XBTC);
        delete validIds[myid];
        updateValue();
    }

    function updateValue() internal {
        uint balance = FuturesExchToken(futuresExch).balanceOf(this);
        if (balance > 0) FuturesExchToken(futuresExch).withdraw(balance);
        balance = 0;
        if (oraclize_getPrice("URL") > this.balance) {
            newOraclizeQuery("Oraclize query was NOT sent, please add some ETH to cover for the query fee");
        } else {
            newOraclizeQuery("Oraclize query was sent, standing by for the answer..");
            bytes32 queryId =
                oraclize_query(getPeriod(), "URL", URL);
            validIds[queryId] = true;
        }
    }
    
    function getPeriod() internal view returns (uint){
        return DateTimeAPI.toTimestamp(DateTimeAPI.getYear(now), DateTimeAPI.getMonth(now), DateTimeAPI.getDay(now)) + 64800; //Next Day 16:00 UTC
    }*/

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
    
    function stringToUint(string _amount) internal constant returns (uint result) {
        bytes memory b = bytes(_amount);
        uint i;
        uint counterBeforeDot;
        uint counterAfterDot;
        uint totNum = b.length;
        totNum--;        
        result = 0;        
        bool hasDot = false;
        for (i = 0; i < b.length; i++) {
            uint c = uint(b[i]);
            if (c >= 48 && c <= 57) {
                result = result.mul(10).add(c.sub(48));
                counterBeforeDot++;
                totNum--;
            }
            if(c == 46){
                hasDot = true;
                break;
            }
        }        
        if(hasDot) {
            for (uint j = counterBeforeDot + 1; j < b.length && j < (counterBeforeDot + decimals) && totNum > 0; j++) {
                uint m = uint(b[j]);
    
                if (m >= 48 && m <= 57) {
                    result = result.mul(10).add(m.sub(48));
                    counterAfterDot ++;
                    totNum--;
                }
            }
            
            if(counterAfterDot < decimals){
                uint addNum = uint(decimals).sub(counterAfterDot);
                uint multuply = 10 ** addNum;
                return result = result.mul(multuply);
            }
        }        
    }
    
    function invertTrade() public onlyOwner returns (bool){
        trade = !trade;
        //if (trade) updateValue();
        return trade;
    }
    
    /*function getCost(uint _size) public view returns (uint){
        require(history.length > 1);
        return _size*history[history.length-1].value;
    }*/
    
    function roundPrice(uint _price) public view returns (uint value){
        uint _v = _price % tick_size;
        value = _v < tick_size.div(2) ? _price.sub(_v) : _price.sub(_v).add(tick_size);
    }

    /*function transfer(address _to, uint256 _value) public onlyChanger returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public onlyChanger returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }
    
    function increaseApproval(address _spender, uint _addedValue) public onlyChanger returns (bool success) {
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public onlyChanger returns (bool success) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }*/
    
    function setLast(uint _last) external onlyChanger returns(bool){
        last = _last;
        return true;
    }
    
    function kill() public onlyOwner {
        require(now > expire);
        selfdestruct(owner);
    }
    
}