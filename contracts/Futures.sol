pragma solidity ^0.4.18;

import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "zeppelin-solidity/contracts/ownership/CanReclaimToken.sol";
//import "zeppelin-solidity/contracts/token/StandardToken.sol";
import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "zeppelin-solidity/contracts/math/Math.sol";
import "./FuturesExchToken.sol";
import "oraclize/ethereum-api/oraclizeAPI.sol";
import "library/DateTime.sol";

import "./Controlled.sol";

contract Futures is Ownable, Controlled, CanReclaimToken, usingOraclize {

    using SafeMath for uint256;
    using Math for uint256;
    
    uint constant CLEARING_TIME = 64800; // Day 18:00 UTC
    uint constant DAY_IN_SECONDS = 86400;

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
    uint last;
    mapping(bytes32=>bool) validIds;
    mapping(address => Checkpoint[]) balances;
    Checkpoint[] history;

    struct Checkpoint {
        uint dt;
        uint price;
        uint value;
        KIND kind;
    }
    
    enum KIND {NULL, SELL, BUY}
    
    event updatedPrice(uint value);
    event clearingValue(uint value);
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
        futuresExch = _futuresExch;
        URL = url;
        addChanger(_futuresExch);
    }
    
    function() public payable { }

    function transferFrom(address _from, address _to, uint256 _value, uint256 _price) public onlyChanger returns (bool) {
        require(_to != address(0));
        require(_from != address(0));
        balances[_from].push(Checkpoint({dt: now, price: _price, value: _value, kind: KIND.SELL}));
        balances[_to].push(Checkpoint({dt: now, price: _price, value: _value, kind: KIND.BUY}));

        Transfer(_from, _to, _value);
        return true;
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
    
    function roundPrice(uint _price) public view returns (uint value){
        uint _v = _price % tick_size;
        value = _v < tick_size.div(2) ? _price.sub(_v) : _price.sub(_v).add(tick_size);
    }

    function setLast(uint _last) external onlyChanger returns(bool){
        last = _last;
        return true;
    }
    
    function kill() public onlyOwner {
        require(now > expire);
        uint balance = FuturesExchToken(futuresExch).balanceOf(this);
        if (balance > 0) FuturesExchToken(futuresExch).withdraw(balance);        
        selfdestruct(owner);
    }
    
    function clearing(address trader) public onlyChanger returns(int result) {
        require(!trade);
        require(balances[trader].length > 0);
        require(balances[trader][0].dt < DateTime.toTimestamp(DateTime.getYear(now), DateTime.getMonth(now), DateTime.getDay(now)) + CLEARING_TIME);
        uint last_prev = history.length > 1 ? history[history.length-2].value : last;
        
        result += last >= last_prev ? int(last.sub(last_prev).mul(balances[trader][0].value)): int(last_prev.sub(last).mul(balances[trader][0].value)) * (-1);
        balances[trader][0].dt = now;
        
        for(uint i = balances[trader].length - 1; i > 0; i-- ){
            //balances[trader][i].dt
            result += last >= balances[trader][i].price ? int(last.sub(balances[trader][i].price).mul(balances[trader][i].value)): int(balances[trader][i].price.sub(last).mul(balances[trader][i].value)) * (-1);
            
            if (balances[trader][0].kind == balances[trader][i].kind) balances[trader][0].value +=  balances[trader][i].value;
            else {
                balances[trader][0].value = balances[trader][0].value >= balances[trader][i].value ? balances[trader][0].value.sub( balances[trader][i].value) : balances[trader][i].value.sub( balances[trader][0].value);
                balances[trader][0].kind = balances[trader][0].value >= balances[trader][i].value ? balances[trader][0].kind: balances[trader][i].kind;
            }
            
            delete balances[trader][i];
            balances[trader].length--;
        }
    }
    
    function __callback(bytes32 myid, string result) public {
        require(trade);
        require(validIds[myid]);
        require(msg.sender == oraclize_cbAddress());
        
        //roundPrice((base**decimals).mul(base**decimals).div(stringToUint(result)).mul(size).div(base**decimals))
        uint XBTC = roundPrice((uint(10)**decimals).mul(size).div(stringToUint(result)));
        history.push(Checkpoint({dt: DateTime.toTimestamp(DateTime.getYear(now), DateTime.getMonth(now), DateTime.getDay(now)) + CLEARING_TIME,
                    price: XBTC, value: last, kind: KIND.NULL}));
        updatedPrice(XBTC);
        clearingValue(last);
        delete validIds[myid];
        updateValue();
        trade = false;
    }

    function updateValue() internal {
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
        return DateTime.toTimestamp(DateTime.getYear(now), DateTime.getMonth(now), DateTime.getDay(now)) + DAY_IN_SECONDS + CLEARING_TIME;
    }
    
    function start() public onlyOwner{
        require(this.balance > 0);
        if(!trade) invertTrade();
        updateValue();
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
}