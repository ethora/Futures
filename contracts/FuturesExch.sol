pragma solidity ^0.4.17;


import "./FuturesAPI.sol";
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
    
    function CreateFuturesAPI(string _name, string _symbol, address _addressTicker, uint _expire, 
                        uint _size, uint _tick_size, uint _tick_value, uint _margin, uint8 _decimals) 
    public onlyOwner returns (address) {
        require(_addressTicker != address(0));
        
        //Futures _futures = new FuturesAPI(_name, _symbol, _addressTicker, _expire, _size, _tick_size, _tick_value, _margin, _decimals);
        address _futures = FuturesAPI.CreateFutures(_name, _symbol, _addressTicker, _expire, _size, _tick_size, _tick_value, _margin, _decimals); 
        futuresList.push(_futures);
        NewFutures(_futures, _symbol);    
        return _futures;
    }
    
    function Buy(address _futures, uint _size) public returns (uint) {
        require(_size > 0);
        uint _cost = FuturesExchLib.Buy(AskList, orders[_futures], _futures, _size, order_id);
        traderOrders[msg.sender].push(order_id);
        if(_cost > 0) transfer(this, _cost);
        order_id++;
        return order_id;
    }
    
    function BuyLimit(address _futures, uint _size, uint _price) public returns (uint) {
        require(_size > 0 && _price > 0);
        var (, value) = EthOraAPI(FuturesAPI.addressTicker(_futures)).getLast();
        if (uint(value).mul(uint(10)**decimals)
                        .div(EthOraAPI(FuturesAPI.addressTicker(_futures)).decimals() > 0 ? uint(10)**EthOraAPI(FuturesAPI.addressTicker(_futures)).decimals() : uint(10)**FuturesAPI.decimals(_futures)) < _price) 
            return Buy(_futures, _size);
        transfer(this, FuturesExchLib.BuyLimit(AskList, orders[_futures], _futures, _size, _price, order_id));
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
        return FuturesAPI.getCheckpoint(_futures, decimals);
    }
    
    function getTick_size(address _futures) public view returns (uint){
        return FuturesAPI.getTick_size(_futures, decimals);
    }
    
    function getSize(address _futures) public view returns (uint){
        return FuturesAPI.getSize(_futures, decimals);
    }  
    
    function getMargin(address _futures) public view returns (uint){
        return FuturesAPI.getMargin(_futures, decimals);
    }        

    function getExpire(address _futures) public view returns (uint){
        return FuturesAPI.getExpire(_futures);
    }    
    
    function getTicker(address _futures) public view returns (address){
        return FuturesAPI.getTicker(_futures);
    }   

    function getDecimals(address _futures) public view returns (uint8){
        return FuturesAPI.getDecimals(_futures);
    }     
    
    function stopFutures(address _futures) public onlyOwner returns (bool){
        return FuturesAPI.stopFutures(_futures);
    }
    
    function startFutures(address _futures) public onlyOwner returns (bool){
        return FuturesAPI.startFutures(_futures);
    }    
    
    function TikerInsert(address _addressTicker, int64 _key, int _value) public onlyOwner {
        require(_addressTicker != address(0));
        EthOraAPI(_addressTicker).insert(_key, _value);
    }
    
    function transferOwnershipForFutures(address futures, address newOwner) public onlyOwner {
        FuturesAPI.transferOwnershipForFutures(futures, newOwner);
    }
    
    /*function bytes32ToString (bytes32 data) public pure returns (string) {
        bytes memory bytesString = new bytes(32);
        for (uint j=0; j<32; j++) {
            byte char = byte(bytes32(uint(data) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[j] = char;
            }
        }
        return string(bytesString);
    }*/
}
