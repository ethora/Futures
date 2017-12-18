pragma solidity ^0.4.17;

import "zeppelin-solidity/contracts/token/StandardToken.sol";
import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "./Futures.sol";
//import "library/DateTimeAPI.sol";
//import "library/linkedList.sol";
import "../../smartoracle/contract/contracts/EthOra.sol";

contract FuturesExch is StandardToken, Ownable {
    
    string public name;
    string public symbol;
    uint8 public decimals;
    //DateTimeAPI internal datetime;
    FuturesList[] internal futuresList;
    mapping(address => Order[]) internal orders;
    uint internal order_id;
    //DoublyLinkedList.data OrderBook;

    event NewFutures(address futures, string symbol);
    event LogOrder(address indexed futures, string symbol, Kind kind, Action action, uint id, uint size, uint price);
    
    struct FuturesList {
        address futures;
        uint expire;
        bool trade;
    }
    
    struct Order {
        uint id;
        address trader;
        Kind kind;
        Action action;
        uint size;
        uint price;
    }
    
    enum Kind { Buy, Sell }
    enum Action { New, Deleted, Done }
    
    function FuturesExch(string _name, string _symbol, uint8 _decimals) public {
        //datetime = DateTimeAPI("0xD5122765dE942CaA344c6Ae02DadC1Cab9C4D49F");
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }
    
    function CreateFutures(string _name, string _symbol, address _addressTicker, uint _expire, uint _value,
                        uint _size, uint _tick_size, uint8 _margin, uint8 _decimals) 
    public onlyOwner returns (Futures) {
        require(_addressTicker != address(0));
        EthOra _ethora = EthOra(_addressTicker);
        var (key, value) = EthOra(_addressTicker).getLast();
        Futures _futures = new Futures(_name, _symbol, _addressTicker, _expire, _value, _size, _tick_size, _margin, _decimals);
        
        futuresList.push(FuturesList({futures:_futures, expire: _expire, trade: true}));
        NewFutures(_futures, bytes32ToString(_futures.getSymbol()));    
        return _futures;
    }
    
    function () payable public {
        require(doPayment());
    }
    
    function doPayment() internal returns (bool){
        uint amount = msg.value;
        require(amount > 0);
        require(increaseApproval(this, amount));
        balances[msg.sender] = balanceOf(msg.sender).add(amount);
        totalSupply = totalSupply.add(amount);
        Transfer(0, msg.sender, amount);
        return true;
    }
    
    function asyncSend(address dest, uint amount) internal returns (bool){
        require(dest != address(0));
        require(amount > 0);
        totalSupply = totalSupply.add(amount);
        balances[dest] = balanceOf(dest).add(amount);
        allowed[dest][this] = allowed[dest][this].add(amount);
        Transfer(0, dest, amount);
        Approval(dest, this, allowed[dest][this]);        
        return true;
    }
    
    function asyncRequest(address from, uint amount) internal returns (bool){
        require(from != address(0));
        require(amount > 0);
        require(totalSupply >= amount);
        require(balances[from] >= amount);
        require(allowed[from][this] >= amount);
        totalSupply = totalSupply.sub(amount);
        balances[from] = balanceOf(from).sub(amount);
        Transfer(from, 0, amount);
        Approval(from, this, allowed[from][this]);  
        return true;
    }
    
    function withdraw(uint amount) public returns (bool){
        require(amount > 0);
        require(balances[msg.sender] >= amount);
        require(decreaseApproval(this, amount));
        balances[msg.sender] = balanceOf(msg.sender).sub(amount);
        totalSupply = totalSupply.sub(amount);
        msg.sender.transfer(amount);
        return true;
    }

    function getCheckpoint(address _futures) public view returns(uint, uint, uint, uint, uint){
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
    
    function Buy(address _futures, uint _size) public returns (uint) {
        require(_futures != address(0));
        require(Futures(_futures).expire() >= now);
        orders[_futures].push(Order({id: order_id, trader: msg.sender, kind: Kind.Buy, action: Action.New, size: _size, price: 0}));
        LogOrder(_futures, bytes32ToString(Futures(_futures).getSymbol()), Kind.Buy, Action.New, order_id, _size, 0);        
        require(Deal(_futures, order_id));
        return order_id++;
    }
    
    function Sell(address _futures, uint _size) public returns (uint) {
        require(_futures != address(0));
        require(Futures(_futures).expire() >= now);
        require(Futures(_futures).balanceOf(msg.sender) >= _size);
        orders[_futures].push(Order({id: order_id, trader: msg.sender, kind: Kind.Sell, action: Action.New, size: _size, price: 0}));
        LogOrder(_futures, bytes32ToString(Futures(_futures).getSymbol()), Kind.Sell, Action.New, order_id, _size, 0);        
        require(Deal(_futures, order_id));
        return order_id++;
    }
    
    function Deal(address _futures, uint _order_id) internal returns (bool){
        uint i = 0;
        for (i = orders[_futures].length; ((orders[_futures][i-1].id != _order_id) && (i >= 0)) ; i--){}
        
        return true;
    }
    
    function TikerInsert(address _addressTicker, int64 _key, int _value) public onlyOwner {
        require(_addressTicker != address(0));
        EthOra _ethora = EthOra(_addressTicker);
        _ethora.insert(_key, _value);
    }
    
    function transferOwnershipForFutures(address futures, address newOwner) public onlyOwner {
        require(futures != address(0));
        require(newOwner != address(0));
        Futures(futures).transferOwnership(newOwner);
    }
    
    function bytes32ToString (bytes32 data) internal pure returns (string) {
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
