pragma solidity ^0.4.18;

import "./Futures.sol";
import "./FuturesExchToken.sol";
import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "zeppelin-solidity/contracts/math/Math.sol";


contract FuturesExch is FuturesExchToken {

    using SafeMath for uint256;
    using Math for uint256;
    
    uint constant maker_fee = 50; // 0.05% * 1000
    uint constant taker_fee = 100;// 0.10% * 1000
    uint public order_id;
    address[] futuresList;
    //etherdelta inspire
    mapping (address => mapping (bytes32 => bool)) public orders; //mapping of user accounts to mapping of order hashes to booleans (true = submitted by user, equivalent to offchain signature)
    mapping (address => mapping (bytes32 => uint)) public orderFills; //mapping of user accounts to mapping of order hashes to uints (amount of order that has been filled)    

    event LogOrder(address indexed futures, uint id, uint size, uint8 kind, uint price, uint expires, uint nonce, address user);
    event LogCancel(address indexed futures, uint id, uint size, uint8 kind, uint price, uint expires, uint nonce, address user);
    event LogTrade(address indexed futures, uint id, uint size, uint8 kind, uint price, address maker, address taker);
    event NewFutures(address futures, string symbol);
    
    function FuturesExch(string _name, string _symbol, uint8 _decimals) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }
    
    function addFutures(address futures) public onlyOwner returns(bool){
        require(futures != address(0));
        futuresList.push(futures);

        NewFutures(futures, bytes32ToString(Futures(futures).getSymbol()));            

        return true;
    }
    
    function order(address futures, uint size, uint8 kind, uint price, uint expires, uint nonce) public returns (uint) {
        require(kind == 0 || kind == 1);
        uint _price = Futures(futures).roundPrice(price);
        bytes32 hash = sha256(this, futures, order_id, size, kind, _price, expires, nonce);
        orders[msg.sender][hash] = true;
        orderFills[msg.sender][hash] = size;
        LogOrder(futures, order_id, size, kind, _price, expires, nonce, msg.sender);
        return order_id++;
    }    
    
    function cancelOrder(address futures, uint size, uint8 kind, uint price, uint expires, uint nonce, uint _order_id ) public {
        bytes32 hash = sha256(this, futures, _order_id, size, kind, price, expires, nonce);
        require (orders[msg.sender][hash]) ;//???????
        delete orderFills[msg.sender][hash];
        delete orders[msg.sender][hash];
        LogCancel(futures, _order_id, size, kind, price, expires, nonce, msg.sender);
    }    
    
    function trade(address futures, uint size, uint8 kind, uint price, uint expires, uint nonce, address user, uint _order_id /*, uint8 v, bytes32 r, bytes32 s*/) public {
        
        require(kind == 0 || kind == 1); // Buy = 0, Sell = 1
        //uint8 _kind = kind == 0 ? 1 : 0;
        bytes32 hash = sha256(this, futures, _order_id, size, (kind == 0 ? 1 : 0), price, expires, nonce);
        require (!(
          (orders[user][hash] /*|| ecrecover(keccak256("\x19Ethereum Signed Message:\n32", hash),v,r,s) == user*/) &&
          block.number <= expires &&
          orderFills[user][hash] > 0
        )) ;
        //uint part_size = size.min256(orderFills[user][hash]);
        tradeBalances(futures, user, kind, size.min256(orderFills[user][hash]), price);
        orderFills[user][hash] = orderFills[user][hash].sub(size.min256(orderFills[user][hash]));
        LogTrade(futures, _order_id, size.min256(orderFills[user][hash]), kind, price, user, msg.sender);
    }    
    
    function tradeBalances (address futures, address maker, uint8 kind, uint size, uint price) internal {
        uint cost = Futures(futures).roundPrice(price.mul(size).mul(uint(Futures(futures).margin())).div(uint(100)));
        require(cost > 0);
        
        if ( kind == 0 ) {
            //buy from orders
            asyncSend(maker, cost);
            asyncRequest(msg.sender, cost);
            Futures(futures).transferFrom(maker, msg.sender, size, price);
        }
        else {
            //sell to orders
            asyncSend(msg.sender, cost);
            asyncRequest(maker, cost);
            Futures(futures).transferFrom(msg.sender, maker, size, price);
        }
        
        asyncRequest(maker,      cost.mul(maker_fee).div(100000));    
        asyncRequest(msg.sender, cost.mul(taker_fee).div(100000));
        asyncSend(futures, cost.mul(maker_fee).div(100000).add(cost.mul(taker_fee).div(100000)));
    }
    
    function clearing(address futures, address trader) public {
        int variation = Futures(futures).clearing(trader);
        if (variation > 0) asyncSend(trader, uint(variation));
        if (variation < 0) asyncRequest(trader, uint(variation * (-1)));
    }
    
    function getFuturesListLength() public view returns (uint)
    {
        return futuresList.length;
    }
    
    function getFuturesByIdx(uint idx) public view returns (address)
    {
        return futuresList[idx];
    }
    
    function bytes32ToString (bytes32 data) public pure returns (string) {
        bytes memory bytesString = new bytes(32);
        for (uint j=0; j<32; j++) {
            byte char = byte(bytes32(uint(data) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[j] = char;
            }
        }
        return string(bytesString);
    }

}
