pragma solidity ^0.4.18;

contract DataAPI {
    uint public order_id;
    uint8 public BUY = 0;
    uint8 public SELL = 1;
    uint8 public NEW = 0;
    uint8 public DELETED = 1;
    uint8 public DONE = 2;   
    
    struct Order {
        uint id;
        address trader;
        uint8 kind;
        uint8 action;
        uint size;
        uint price;
        bool deleted;
    }        
    
    function addFutures(address _futures) public constant returns(bool);
    function getFuturesListLength() public constant returns (uint);
    function getFuturesByIdx(uint idx) public constant returns (address);
    function findAsk(address futures, uint size, uint price) public constant returns(uint);
    function IncreaseId() public constant returns (uint);
    function getOrder(address futures, uint idx) public constant returns(Order);
}