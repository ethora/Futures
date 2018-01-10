pragma solidity ^0.4.18;

import "./Futures.sol";
import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "zeppelin-solidity/contracts/math/Math.sol";

library FuturesAPI {
    /*using SafeMath for uint256;
    using Math for uint256;

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
    
    function tick_size(address _futures, uint _decimals) public view returns (uint){
        require(_futures != address(0));
        require(Futures(_futures).expire() >= now);
        return Futures(_futures).tick_size().mul(uint(10)**_decimals).div(uint(10)**Futures(_futures).decimals());
    }    
    
    function size(address _futures, uint _decimals) public view returns (uint){
        require(_futures != address(0));
        require(Futures(_futures).expire() >= now);
        return Futures(_futures).size().mul(uint(10)**_decimals).div(uint(10)**Futures(_futures).decimals());
    }      
    
    function margin(address _futures, uint _decimals) public view returns (uint){
        require(_futures != address(0));
        require(Futures(_futures).expire() >= now);
        return Futures(_futures).margin().mul(uint(10)**_decimals).div(uint(10)**Futures(_futures).decimals());
    }       
    
    function round(address _futures, uint _size, uint _price) public view returns (uint){
        require(_futures != address(0));
        require(Futures(_futures).expire() >= now);
        return Futures(_futures).round(_size, _price);
    }
    
    function trade(address _futures) public view returns (bool){
        return Futures(_futures).trade();
    }
    
    function setCheckpoint(address _futures, uint value) public returns (bool){
        return Futures(_futures).setCheckpoint(value);
    }*/
}