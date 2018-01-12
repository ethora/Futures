pragma solidity ^0.4.18;

contract DataAPI {
    uint public order_id;
    uint8 public BUY = 0;
    uint8 public SELL = 1;
    uint8 public NEW = 0;
    uint8 public DELETED = 1;
    uint8 public DONE = 2;   
    
    function addFutures(address _futures) public constant returns(bool);
    function getFuturesListLength() public constant returns (uint);
    function getFuturesByIdx(uint idx) public constant returns (address);
    function findAsk(address futures, uint size, uint price) public constant returns(uint);
    function findBid(address futures, uint size, uint price) public constant returns(uint);
    function IncreaseId() public constant returns (uint);
    function getOrder(address futures, uint idx) public constant returns(uint, uint, address, uint);
    function setOrder(address futures, address trader, uint8 kind, uint size, uint price) public constant returns (bool);
    function DecreaseOrder(address futures, uint idx, uint size) public constant returns (bool);
}