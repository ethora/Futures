pragma solidity ^0.4.17;

import "zeppelin-solidity/contracts/token/StandardToken.sol";
import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "./Futures.sol";
import "library/DateTimeAPI.sol";
import "../../smartoracle/contract/contracts/EthOra.sol";

contract FuturesExch is StandardToken, Ownable {
    
    DateTimeAPI internal datetime;
    FuturesList[] internal futuresList;
    mapping(address => Order[]) internal orders;
    uint internal order_id;

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
    
    function FuturesExch() public {
        datetime = DateTimeAPI(0xD5122765dE942CaA344c6Ae02DadC1Cab9C4D49F);
    }
    
    function CreateFutures(string _name, string _symbol, address _addressTicker, uint _expire, 
                        uint _size, uint _tick_size, uint _tick_value, uint8 _margin) 
    public onlyOwner returns (Futures) {
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
        revert();
    }
    
    function deposit() payable public returns (bool){
        uint amount = msg.value;
        require(amount > 0);
        require(increaseApproval(this, amount));
        balances[msg.sender] = balanceOf(msg.sender).add(amount);
        return true;
    }
    
    function withdraw(uint amount) public returns (bool){
        require(amount > 0);
        require(balances[msg.sender] >= amount);
        require(decreaseApproval(this, amount));
        balances[msg.sender] = balanceOf(msg.sender).sub(amount);
        msg.sender.transfer(amount);
        return true;
    }
    
    function getFutures() public view returns (uint, FuturesList[]){
        FuturesList[] memory _futuresList;
        uint _size;
        for(uint i = futuresList.length; ((i > 0) && (futuresList[i].expire >= now)); i--){
            _futuresList[_size++] = futuresList[i-1];
        }
        return (_size, _futuresList);
    }
    
    function TikerInsert(address _addressTicker, int64 _key, int _value) public onlyOwner {
        EthOra _ethora = EthOra(_addressTicker);
        _ethora.insert(_key, _value);
    }
    
    function transferOwnershipForFutures(address futures, address newOwner) public onlyOwner {
        require(newOwner != address(0));
        Futures(futures).transferOwnership(newOwner);
    }
}
