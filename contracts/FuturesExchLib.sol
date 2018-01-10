pragma solidity ^0.4.18;

import "./Futures.sol";
import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "zeppelin-solidity/contracts/math/Math.sol";
import "library/linkedList.sol";
import "./DataAPI.sol";

library FuturesExchLib {
    using SafeMath for uint256;
    using Math for uint256;
    using DoublyLinkedList for DoublyLinkedList.data;

    event LogOrder(address indexed futures, uint indexed id, uint8 kind, uint8 action, uint size, uint price);
    
    function Buy(address futures, uint size, address dataContract) public returns (uint) {
        require(futures != address(0));
        require(dataContract != address(0));
        require(Futures(futures).trade());   
        require(Futures(futures).expire() >= now);
        
        LogOrder(futures, DataAPI(dataContract).order_id(), DataAPI(dataContract).BUY(), DataAPI(dataContract).NEW(), size, 0);      
        
        DataAPI(dataContract).findAsk(futures, size, 0);
        
        return ;
    }

    /*function Buy(DoublyLinkedList.data storage _list, Order[] storage _orders, address _futures, uint _size, uint order_id) public returns (uint cost) {
        require(_futures != address(0));
        require(FuturesAPI.expire(_futures) >= now);
        require(FuturesAPI.getTrade(_futures));

        LogOrder(_futures, order_id, BUY, NEW, _size, 0);        
        uint80 it = _list.iterate_end();
        uint part_size = 0;
        while (_list.iterate_valid(it) && _size > 0) {
            if ( _orders[uint(_list.iterate_get(it))].kind != BUY && !_orders[uint(_list.iterate_get(it))].deleted)
            {
                part_size = _size.min256(_orders[uint(_list.iterate_get(it))].size);
                _size -= part_size;
                _orders[uint(_list.iterate_get(it))].size -= part_size;
                cost += part_size.mul(_orders[uint(_list.iterate_get(it))].price).mul(FuturesAPI.getMargin(_futures, 18)).div(100);
                LogOrder(_futures, order_id, BUY, DONE, part_size, _orders[uint(_list.iterate_get(it))].price);
                LogOrder(_futures, _orders[uint(_list.iterate_get(it))].id, SELL, DONE, part_size, _orders[uint(_list.iterate_get(it))].price);   
                //FuturesAPI(_futures).generateTokens(msg.sender, part_size*(uint(10)**FuturesAPI.decimals(_futures)));
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
        require(FuturesAPI.expire(_futures) >= now);
        require(FuturesAPI.getTrade(_futures));

        LogOrder(_futures, order_id, SELL, NEW, _size, 0);        
        return ++order_id;
    }
    
    function BuyLimit(DoublyLinkedList.data storage _list, Order[] storage _orders, address _futures, uint _size, uint _price, uint order_id) public returns (uint){
        require(_futures != address(0));
        require(FuturesAPI.expire(_futures) >= now);
        require(FuturesAPI.getTrade(_futures));
        uint80 it = _list.iterate_end();
        while (_list.iterate_valid(it)) {
            if ( _list.count == 0 ||(_orders[uint(_list.iterate_get(it))].kind == BUY && !_orders[uint(_list.iterate_get(it))].deleted && _orders[uint(_list.iterate_get(it))].price > _price)){
                _list.insert_after(it, bytes32(_orders.push(Order({id: order_id, trader: msg.sender, kind: BUY, action: NEW, size: _size, price: _price, deleted: false}))));
                LogOrder(_futures, order_id, BUY, NEW, _size, _price); 
                return FuturesAPI.round(_futures, 1, _size.mul(_price).mul(FuturesAPI.getMargin(_futures, 18)).div(100));
            }        
            it = _list.iterate_prev(it);
        }
    }*/

}