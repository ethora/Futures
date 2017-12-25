pragma solidity ^0.4.17;

import "./Futures.sol";
import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "zeppelin-solidity/contracts/math/Math.sol";

library FuturesAPI {
    using SafeMath for uint256;
    using Math for uint256;

    event StatusFutures(address futures, bool trade);

    
    function CreateFutures(string _name, string _symbol, address _addressTicker, uint _expire, 
                        uint _size, uint _tick_size, uint _tick_value, uint _margin, uint8 _decimals) 
    public returns (address) {
        require(_addressTicker != address(0));
        
        Futures _futures = new Futures(_name, _symbol, _addressTicker, _expire, _size, _tick_size, _tick_value, _margin, _decimals);
        return _futures;
    }    
    
    function getSymbol(address _futures) public view returns(bytes32 result) {
        require(_futures != address(0));
        return Futures(_futures).getSymbol();
    }
    
    function addressTicker(address _futures) public view returns (address){
        require(_futures != address(0));    
        return Futures(_futures).addressTicker();
    }
    
    function decimals(address _futures) public view returns (uint){
        require(_futures != address(0));    
        return Futures(_futures).decimals();
    }    
    
    function expire(address _futures) public view returns (uint){
        require(_futures != address(0));    
        return Futures(_futures).expire();
    }        
    
    function getCheckpoint(address _futures, uint _decimals) public view returns (uint, uint, uint, uint) {
        require(_futures != address(0));
        require(Futures(_futures).expire() >= now);        
        var (last, high, low, settlement) = Futures(_futures).getCheckpoint();
        return (last.mul(uint(10)**_decimals).div(uint(10)**Futures(_futures).decimals()),
                high.mul(uint(10)**_decimals).div(uint(10)**Futures(_futures).decimals()),
                low.mul(uint(10)**_decimals).div(uint(10)**Futures(_futures).decimals()),
                settlement.mul(uint(10)**_decimals).div(uint(10)**Futures(_futures).decimals()));
    }
    
    function getTick_size(address _futures, uint _decimals) public view returns (uint){
        require(_futures != address(0));
        require(Futures(_futures).expire() >= now);
        return Futures(_futures).tick_size().mul(uint(10)**_decimals).div(uint(10)**Futures(_futures).decimals());
    }    
    
    function getSize(address _futures, uint _decimals) public view returns (uint){
        require(_futures != address(0));
        require(Futures(_futures).expire() >= now);
        return Futures(_futures).size().mul(uint(10)**_decimals).div(uint(10)**Futures(_futures).decimals());
    }      
    
    function getMargin(address _futures, uint _decimals) public view returns (uint){
        require(_futures != address(0));
        require(Futures(_futures).expire() >= now);
        return Futures(_futures).margin().mul(uint(10)**_decimals).div(uint(10)**Futures(_futures).decimals());
    }       
    
    function getExpire(address _futures) public view returns (uint){
        require(_futures != address(0));
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
    
    function stopFutures(address _futures) public returns (bool){
        require(_futures != address(0));
        require(Futures(_futures).expire() >= now);
        require(Futures(_futures).trade());
        require(!Futures(_futures).invertTrade());
        StatusFutures(_futures, Futures(_futures).trade());
        return true;
    }    
    
    function startFutures(address _futures) public returns (bool){
        require(_futures != address(0));
        require(Futures(_futures).expire() >= now);
        require(!Futures(_futures).trade());
        require(Futures(_futures).invertTrade());
        StatusFutures(_futures, Futures(_futures).trade());
        return true;
    }       
    
    function transferOwnershipForFutures(address futures, address newOwner) public {
        require(futures != address(0));
        require(newOwner != address(0));
        Futures(futures).transferOwnership(newOwner);
    }    
}