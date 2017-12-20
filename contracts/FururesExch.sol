pragma solidity ^0.4.17;

import "zeppelin-solidity/contracts/token/StandardToken.sol";
import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "./Futures.sol";
//import "library/DateTimeAPI.sol";
//import "library/linkedList.sol";
import "../../smartoracle/contract/contracts/EthOra.sol";
import "./FuturesExchLib.sol";

contract FuturesExch is StandardToken, Ownable {
    
    string public name;
    string public symbol;
    uint8 public decimals;
    //DateTimeAPI internal datetime;
    mapping(address => FuturesExchLib.Order[]) internal orders;
    uint internal order_id;
    
    address[] futuresList;
    //DoublyLinkedList.data OrderBook;

    
    event LogOrder(address indexed futures, uint8 kind, uint8 action, uint id, uint size, uint price);
    event NewFutures(address futures, string symbol);
    event StatusFutures(address futures, bool trade);
    
    function FuturesExch(string _name, string _symbol, uint8 _decimals) public {
        //datetime = DateTimeAPI("0xD5122765dE942CaA344c6Ae02DadC1Cab9C4D49F");
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }
    
    function CreateFutures(string _name, string _symbol, address _addressTicker, uint _expire, 
                        uint _size, uint _tick_size, uint _tick_value, uint8 _margin, uint8 _decimals) 
    public onlyOwner returns (Futures) {
        require(_addressTicker != address(0));
        var (key, value) = EthOra(_addressTicker).getLast();
        
        Futures _futures = new Futures(_name, _symbol, _addressTicker, _expire, uint256(value), _size, _tick_size, _tick_value, _margin, _decimals);
        futuresList.push(_futures);
        NewFutures(_futures, bytes32ToString(_futures.getSymbol()));    
        return _futures;
    }
    
    function Buy(address _futures, uint _size) public returns (uint) {
        require(_size > 0);
        uint _cost = _size.mul(Futures(_futures).getLast()).mul(uint(10)**decimals).div(uint(10)**Futures(_futures).decimals()).mul(Futures(_futures).margin()).div(100);
        require(balanceOf(msg.sender) >= _cost);
        order_id = FuturesExchLib.Buy(orders[_futures] ,_futures, _size, order_id);
        transfer(this, _cost);
        //LogOrder(msg.sender, 0,0,0,0,_cost);
        return order_id;
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
        EthOra _ethora = EthOra(_addressTicker);
        _ethora.insert(_key, _value);
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
