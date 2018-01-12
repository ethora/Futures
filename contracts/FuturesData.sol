pragma solidity ^0.4.18;

import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "zeppelin-solidity/contracts/ownership/HasNoEther.sol";
import "library/linkedList.sol";
import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "zeppelin-solidity/contracts/math/Math.sol";
import "./Controlled.sol";

contract FuturesData is Ownable, Controlled, HasNoEther {
    
    using DoublyLinkedList for DoublyLinkedList.data;
    using SafeMath for uint256;
    using Math for uint256;
    
    address[] futuresList;
    mapping(address => Order[]) orders;
    mapping(address => uint[]) traderOrders;
    DoublyLinkedList.data AskList; //Sell orders
    DoublyLinkedList.data BidList; //Buy orders  
    
    
    uint public order_id;
    
    uint8 constant BUY = 0;
    uint8 constant SELL = 1;
    uint8 constant NEW = 0;
    uint8 constant DELETED = 1;
    uint8 constant DONE = 2;    
    
    struct Order {
        uint id;
        address trader;
        uint8 kind;
        //uint8 action;
        uint size;
        uint price;
        bool active;
    }    
    
    function findAsk(address futures, uint size, uint price) public view returns (uint){
        return findOrder(AskList, futures, size, price, SELL);
    }
    
    function findBid(address futures, uint size, uint price) public view returns (uint){
        return findOrder(BidList, futures, size, price, BUY);
    }    
    
    function findOrder(DoublyLinkedList.data storage List, address futures, uint size, uint price, uint8 kind) internal view returns(uint){
        require(size > 0);
        var it = List.iterate_end();
        while (List.iterate_valid(it)){
            if(orders[futures][List.iterate_get(it)].kind == kind && orders[futures][List.iterate_get(it)].active && orders[futures][List.iterate_get(it)].size > 0) {
                if (price == 0) return it;
                else {
                    if ( kind == SELL && orders[futures][List.iterate_get(it)].price <= price ) return it;
                    if ( kind == BUY  && orders[futures][List.iterate_get(it)].price >= price ) return it;
                }
            }
            it = List.iterate_prev(it);
        }
        return;
    }
    
    function getOrder(address futures, uint idx) public view returns(uint, uint, address, uint){
        return (orders[futures][idx].size, orders[futures][idx].price, orders[futures][idx].trader, orders[futures][idx].id);
    }
    
    function setOrder(address futures, address trader, uint8 kind, uint size, uint price) public onlyChanger returns (bool) {
        orders[futures].push(Order({id: order_id, trader: trader, kind: kind, size: size, price: price, active: true}));
        return true;
    }
    
    function addFutures(address futures) public onlyChanger returns(bool){
        require(futures != address(0));
        futuresList.push(futures);
        return true;
    }
    
    function IncreaseId() public onlyChanger returns (uint){
        return ++order_id;
    }
    
    function DecreaseOrder(address futures, uint idx, uint size) public onlyChanger returns (bool){
        require (orders[futures][idx].active);
        require (orders[futures][idx].size >= size);
        orders[futures][idx].size.sub(size);
        if (orders[futures][idx].size == 0) delete orders[futures][idx];
        return true;
    }

    function getFuturesListLength() public view returns (uint)
    {
        return futuresList.length;
    }
    
    function getFuturesByIdx(uint idx) public view returns (address)
    {
        require((idx < futuresList.length) && (idx >= 0));
        return futuresList[idx];
    }

}
