pragma solidity ^0.4.18;

import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "library/linkedList.sol";

contract FuturesData is Ownable {
    
    using DoublyLinkedList for DoublyLinkedList.data;
    
    address[] futuresList;
    mapping(address => Order[]) orders;
    mapping(address => uint[]) traderOrders;
    DoublyLinkedList.data AskList; //Sell orders
    DoublyLinkedList.data BidList; //Buy orders  
    mapping(address => bool) changers;
    
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
        uint8 action;
        uint size;
        uint price;
        bool deleted;
    }    
    
    function FuturesData() public {
        changers[msg.sender] = true;
    }
    
    function findAsk(address futures, uint size, uint price) public view returns (uint){
        return findOrder(AskList, futures, size, price, SELL);
    }
    
    function findOrder(DoublyLinkedList.data storage List, address futures, uint size, uint price, uint8 kind) internal view returns(uint){
        require(size > 0);
        var it = List.iterate_end();
        while (List.iterate_valid(it)){
            if(orders[futures][List.iterate_get(it)].kind == kind && !orders[futures][List.iterate_get(it)].deleted && orders[futures][List.iterate_get(it)].size > 0) {
                return it;
            }
            it = List.iterate_prev(it);
        }
        return;
    }
    
    function getOrder(address futures, uint idx) public view returns(Order){
        return orders[futures][idx];
    }
    
    function addFutures(address _futures) public onlyOwner returns(bool){
        require(_futures != address(0));
        futuresList.push(_futures);
        return true;
    }
    
    function IncreaseId() public onlyChanger returns (uint){
        return ++order_id;
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

    function kill() public onlyOwner {
        selfdestruct(owner);
    }
    
    function () payable public {
        revert();
    }    

    modifier onlyChanger() {
        require(changers[msg.sender]);
        _;
    }

    function addChanger(address newChanger) public onlyOwner {
        require(newChanger != address(0));
        changers[newChanger] = true;
    }
}
