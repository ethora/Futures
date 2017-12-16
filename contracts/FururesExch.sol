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

    event NewFutures(Futures futures);
    
    struct FuturesList {
        address futures;
        uint expire;
        bool trade;
    }
    
    struct Order {
        uint id;
        address trader;
        ActionType action;
        uint size;
        uint price;
    }
    
    enum ActionType { Bid, Ask }
    
    function FuturesExch(string _name, string _symbol, uint8 _decimals) public {
        //datetime = DateTimeAPI("0xD5122765dE942CaA344c6Ae02DadC1Cab9C4D49F");
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }
    
    function CreateFutures(string _name, string _symbol, address _addressTicker, uint _expire, 
                        uint _size, uint _tick_size, uint _tick_value, uint8 _margin) 
    public onlyOwner returns (Futures) {
        require(_addressTicker != address(0));
        EthOra _ethora = EthOra(_addressTicker);
        var (key, value) = _ethora.getLast();
        Futures _futures = new Futures(_name, _symbol, _addressTicker, _expire, uint(value), _size, _tick_size, _tick_value, _margin);
        
        FuturesList memory _futuresList;
        _futuresList.futures = _futures;
        _futuresList.expire = _expire;
        _futuresList.trade = true;
        
        futuresList.push(_futuresList);
        futuresList.length++;
        NewFutures(_futures);
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
    
    function getFutures() public view returns (uint, address[]){
        address[] memory _futures;
        uint _size;
        for(uint i = futuresList.length; ((i > 0) && (futuresList[i].expire >= now)); i--){
            _futures[_size++] = futuresList[i-1].futures;
        }
        return (_size, _futures);
    }
    
    function Buy() public pure {
    
    }
    
    function Sell() public pure {
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
}
