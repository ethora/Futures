pragma solidity ^0.4.17;

import "./Futures.sol";
import "zeppelin-solidity/contracts/math/SafeMath.sol";

library FuturesExchLib {
    using SafeMath for uint256;

    struct Order {
        uint id;
        address trader;
        uint8 kind;
        uint8 action;
        uint size;
        uint price;
        bool deleted;
    }
    
    //enum Kind { Buy, Sell }
    //enum Action { New, Deleted, Done }    
    
    uint8 constant BUY = 0;
    uint8 constant SELL = 1;
    uint8 constant NEW = 0;
    uint8 constant DELETED = 1;
    uint8 constant DONE = 2;
    
    event LogOrder(address indexed futures, uint8 kind, uint8 action, uint id, uint size, uint price);

    function Buy(Order[] storage orders, address _futures, uint _size, uint order_id) public returns (uint) {
        require(_futures != address(0));
        require(Futures(_futures).expire() >= now);
        require(Futures(_futures).trade());
        orders.push(Order({id: order_id, trader: msg.sender, kind: BUY, action: NEW, size: _size, price: 0, deleted: false}));
        LogOrder(_futures, BUY, NEW, order_id, _size, 0);        
        //require(Deal(_futures, order_id));
        return ++order_id;
    }
    
    function Sell(Order[] storage orders, address _futures, uint _size, uint order_id) public returns (uint) {
        require(_futures != address(0));
        require(Futures(_futures).expire() >= now);
        require(Futures(_futures).trade());
        //require(Futures(_futures).balanceOf(msg.sender) >= _size);
        orders.push(Order({id: order_id, trader: msg.sender, kind: SELL, action: NEW, size: _size, price: 0, deleted: false}));
        LogOrder(_futures, SELL, NEW, order_id, _size, 0);        
        //require(Deal(_futures, order_id));
        return ++order_id;
    }
    
    function DeleteOrder(Order[] storage orders, address _futures, uint _order_id) public returns (bool){
        require(_futures != address(0));
        require(Futures(_futures).expire() >= now);
        require(Futures(_futures).trade());    
        require(orders.length > 0);
        uint i = 0;
        for(i = orders.length; (i > 0 && orders[i-1].id != _order_id) ;i--){}
        if (i == 0) return false;
        else {
            require(orders[i-1].id == _order_id);
            require(orders[i-1].trader == msg.sender);
            require(!orders[i-1].deleted);
            LogOrder(_futures, orders[i-1].kind, DELETED, 
                        orders[i-1].id, orders[i-1].size, orders[i-1].price);        
            orders[i-1].deleted = true;
            return true;
        }
    }    
    
}