pragma solidity ^0.4.17;


import "./Futures.sol";
import "./FuturesExchToken.sol";
import "./EthOraAPI.sol";
import "./FuturesExchLib.sol";
import "library/linkedList.sol";

contract FuturesExch is FuturesExchToken {
    
    using DoublyLinkedList for DoublyLinkedList.data;

    mapping(address => FuturesExchLib.Order[]) internal orders;
    mapping(address => uint[]) internal traderOrders;
    DoublyLinkedList.data AskList; //Sell orders
    DoublyLinkedList.data BidList; //Buy orders
    
    uint internal order_id;
    
    address[] futuresList;

    event LogOrder(address indexed futures, uint indexed id, uint8 kind, uint8 action, uint size, uint price);
    event NewFutures(address futures, string symbol);
    event StatusFutures(address futures, bool trade);
    
    function FuturesExch(string _name, string _symbol, uint8 _decimals) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }
    
    function CreateFutures(string _name, string _symbol, address _addressTicker, uint _expire, 
                        uint _size, uint _tick_size, uint _tick_value, uint8 _margin, uint8 _decimals) 
    public onlyOwner returns (Futures) {
        require(_addressTicker != address(0));
        var (key, value) = EthOraAPI(_addressTicker).getLast();
        
        Futures _futures = new Futures(_name, _symbol, _addressTicker, _expire, uint256(value), _size, _tick_size, _tick_value, _margin, _decimals);
        futuresList.push(_futures);
        NewFutures(_futures, bytes32ToString(_futures.getSymbol()));    
        return _futures;
    }
    
    function Buy(address _futures, uint _size) public returns (uint) {
        require(_size > 0);
        uint _cost = _size.mul(Futures(_futures).getLast()).mul(uint(10)**decimals).div(uint(10)**Futures(_futures).decimals()).mul(Futures(_futures).margin()).div(100);
        require(balanceOf(msg.sender) >= _cost);
        _cost = FuturesExchLib.Buy(AskList, orders[_futures], _futures, _size, order_id);
        traderOrders[msg.sender].push(order_id);
        if(_cost > 0) transfer(this, _cost.mul(uint(10)**decimals));
        order_id++;
        return order_id;
    }
    
    function getFutureListLength() public view returns (uint)
    {
        return futuresList.length;
    }
    
    function getFutureByIdx(uint idx) public view returns (address)
    {
        return futuresList[idx];
    }

    function getCheckpoint(address _futures) public view returns(uint, uint, uint, uint){
        require(_futures != address(0));
        require(Futures(_futures).expire() >= now);
        return Futures(_futures).getCheckpoint();
    }
    
    function getTick_size(address _futures) public view returns (uint){
        require(_futures != address(0));
        require(Futures(_futures).expire() >= now);
        return Futures(_futures).tick_size();
    }
    
    function getSize(address _futures) public view returns (uint){
        require(_futures != address(0));
        require(Futures(_futures).expire() >= now);
        return Futures(_futures).size();
    }  
    
    function getMargin(address _futures) public view returns (uint8){
        require(_futures != address(0));
        require(Futures(_futures).expire() >= now);
        return Futures(_futures).margin();
    }        

    function getExpire(address _futures) public view returns (uint){
        require(_futures != address(0));
        require(Futures(_futures).expire() >= now);
        return Futures(_futures).expire();
    }    
    
    function getTicker(address _futures) public view returns (address){
        require(_futures != address(0));
        require(Futures(_futures).expire() >= now);
        return Futures(_futures).addressTicker();
    }   

    function getDecimals(address _futures) public view returns (uint8){
        require(_futures != address(0));
        require(Futures(_futures).expire() >= now);
        return Futures(_futures).decimals();
    }     
    
    function stopFutures(address _futures) public onlyOwner returns (bool){
        require(_futures != address(0));
        require(Futures(_futures).expire() >= now);
        require(Futures(_futures).trade());
        require(!Futures(_futures).invertTrade());
        StatusFutures(_futures, Futures(_futures).trade());
        return true;
    }
    
    function startFutures(address _futures) public onlyOwner returns (bool){
        require(_futures != address(0));
        require(Futures(_futures).expire() >= now);
        require(!Futures(_futures).trade());
        require(Futures(_futures).invertTrade());
        StatusFutures(_futures, Futures(_futures).trade());
        return true;
    }    
    
    function TikerInsert(address _addressTicker, int64 _key, int _value) public onlyOwner {
        require(_addressTicker != address(0));
        EthOraAPI(_addressTicker).insert(_key, _value);
    }
    
    function transferOwnershipForFutures(address futures, address newOwner) public onlyOwner {
        require(futures != address(0));
        require(newOwner != address(0));
        Futures(futures).transferOwnership(newOwner);
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
