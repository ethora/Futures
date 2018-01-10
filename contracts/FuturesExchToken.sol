pragma solidity ^0.4.18;

import "zeppelin-solidity/contracts/token/StandardToken.sol";
import "zeppelin-solidity/contracts/ownership/Ownable.sol";

contract FuturesExchToken is StandardToken, Ownable {

    string public name;
    string public symbol;
    uint8 public decimals;
    
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
        Transfer(this, dest, amount);
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
        Transfer(from, this, amount);
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
        Transfer(msg.sender, 0, amount);
        return true;
    }    
    
    function kill() public onlyOwner {
        selfdestruct(owner);
    }        
}