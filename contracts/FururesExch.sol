pragma solidity ^0.4.17;

import "zeppelin-solidity/contracts/token/StandardToken.sol";
import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "./Futures.sol";
import "library/DateTimeAPI.sol";

contract FuturesExch is StandardToken, Ownable {
    
    DateTimeAPI internal datetime;

    function FuturesExch() public {
        datetime = DateTimeAPI(0xD5122765dE942CaA344c6Ae02DadC1Cab9C4D49F);
    }
    
    Futures[] internal futuresList;
    
    function CreateFutures(string _name, string _symbol, address _addressTicker, uint _expire) 
    public onlyOwner returns (address) {
        Futures _futures = new Futures(_name, _symbol, _addressTicker, _expire);
        var (key, value) = EthOraAPI(_addressTicker).getLast();
        require(_futures.setSettlement(uint(value)));
        futuresList.push(_futures);
        futuresList.length++;
        return _futures;
    }
}

contract EthOraAPI {
    function getLast() constant public returns (uint64 key, int value);
}