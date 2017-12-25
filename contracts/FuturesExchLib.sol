pragma solidity ^0.4.17;

import "./FuturesAPI.sol";
import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "zeppelin-solidity/contracts/math/Math.sol";
import "library/linkedList.sol";

library FuturesExchLib {
    using SafeMath for uint256;
    using Math for uint256;
    using DoublyLinkedList for DoublyLinkedList.data;

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
    
    event LogOrder(address indexed futures, uint indexed id, uint8 kind, uint8 action, uint size, uint price);

    function Buy(DoublyLinkedList.data storage _list, Order[] storage _orders, address _futures, uint _size, uint order_id) public returns (uint cost) {
        require(_futures != address(0));
        require(Futures(_futures).expire() >= now);
        require(Futures(_futures).trade());

        LogOrder(_futures, order_id, BUY, NEW, _size, 0);        
        uint80 it = _list.iterate_end();
        uint part_size = 0;
        while (_list.iterate_valid(it) && _size > 0) {
            if ( _orders[uint(_list.iterate_get(it))].kind != BUY && !_orders[uint(_list.iterate_get(it))].deleted)
            {
                part_size = _size.min256(_orders[uint(_list.iterate_get(it))].size);
                _size -= part_size;
                _orders[uint(_list.iterate_get(it))].size -= part_size;
                cost += part_size.mul(_orders[uint(_list.iterate_get(it))].price).mul(Futures(_futures).margin()).div(100);
                LogOrder(_futures, order_id, BUY, DONE, part_size, _orders[uint(_list.iterate_get(it))].price);
                LogOrder(_futures, _orders[uint(_list.iterate_get(it))].id, SELL, DONE, part_size, _orders[uint(_list.iterate_get(it))].price);   
                Futures(_futures).generateTokens(msg.sender, part_size*(uint(10)**Futures(_futures).decimals()));
                if (_orders[uint(_list.iterate_get(it))].size == 0 )
                    _orders[uint(_list.iterate_get(it))].deleted = true;   
            }
            it = _list.iterate_prev(it);
        }        

        if (_size > 0) LogOrder(_futures, order_id, BUY, DELETED, _size, 0);
        return cost;
    }
    
    function Sell(address _futures, uint _size, uint order_id) public returns (uint) {
        require(_futures != address(0));
        require(Futures(_futures).expire() >= now);
        require(Futures(_futures).trade());
        //require(Futures(_futures).balanceOf(msg.sender) >= _size);
        //orders.push(Order({id: order_id, trader: msg.sender, kind: SELL, action: NEW, size: _size, price: 0, deleted: false}));
        LogOrder(_futures, order_id, SELL, NEW, _size, 0);        
        //require(Deal(_futures, order_id));
        return ++order_id;
    }
    
    function BuyLimit(DoublyLinkedList.data storage _list, Order[] storage _orders, address _futures, uint _size, uint _price, uint order_id) public returns (uint){
        require(_futures != address(0));
        require(Futures(_futures).expire() >= now);
        require(Futures(_futures).trade());    
        uint80 it = _list.iterate_end();
        while (_list.iterate_valid(it)) {
            if ( _list.count == 0 ||(_orders[uint(_list.iterate_get(it))].kind == BUY && !_orders[uint(_list.iterate_get(it))].deleted && _orders[uint(_list.iterate_get(it))].price > _price)){
                _list.insert_after(it, bytes32(_orders.push(Order({id: order_id, trader: msg.sender, kind: BUY, action: NEW, size: _size, price: _price, deleted: false}))));
                LogOrder(_futures, order_id, BUY, NEW, _size, _price); 
                return Futures(_futures).round(1, _size.mul(_price).mul(Futures(_futures).margin()).div(100));
            }        
            it = _list.iterate_prev(it);
        }
    }

    /*function sort(Order[] storage orders) internal returns (bool){
        if (orders.length < 2) return bool;
        Order memory _order = orders[orders.length - 1];
        for(uint i = orders.length - 2; i>=0; i--){
            if(orders[i].kind == _order.kind && )
        }
    }*/
    
   /* function DeleteOrder(Order[][2] storage orders, address _futures, uint _order_id) public returns (bool){
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
    }    */
    
}