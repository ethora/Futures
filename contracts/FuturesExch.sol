pragma solidity ^0.4.18;

import "./Futures.sol";
import "./FuturesExchToken.sol";
//import "./FuturesExchLib.sol";
import "./DataAPI.sol";
import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "zeppelin-solidity/contracts/math/Math.sol";

contract FuturesExch is FuturesExchToken {

    using SafeMath for uint256;
    using Math for uint256;
    
    address public dataContract;
    
    uint constant maker_fee = 50; // 0.05% * 1000
    uint constant taker_fee = 100;// 0.10% * 1000

    event LogOrder(address indexed futures, uint indexed id, uint8 kind, uint8 action, uint size, uint price);
    event NewFutures(address futures, string symbol);
    
    function FuturesExch(string _name, string _symbol, address _dataContract, uint8 _decimals) public {
        require(_dataContract != address(0));
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        dataContract = _dataContract;
    }
    
    function addFutures(address _futures) public onlyOwner returns(bool){
        require(DataAPI(dataContract).addFutures(_futures));

        NewFutures(_futures, bytes32ToString(Futures(_futures).getSymbol()));            

        return true;
    }
    
    function Buy(address futures, uint size) public returns (bool) {
        require(futures != address(0));
        require(Futures(futures).trade());   
        require(Futures(futures).expire() >= now);        
        
        LogOrder(futures, DataAPI(dataContract).order_id(), DataAPI(dataContract).BUY(), DataAPI(dataContract).NEW(), size, 0);      
        
        uint rest = BuyLoop(futures, size, 0);   
        if (rest > 0) LogOrder(futures, DataAPI(dataContract).order_id(), DataAPI(dataContract).BUY(), DataAPI(dataContract).DELETED(), rest, 0);      

        DataAPI(dataContract).IncreaseId();
        return true;
    }
    
    function BuyLimit(address futures, uint size, uint price) public returns (bool) {
        require(futures != address(0));
        require(Futures(futures).trade());   
        require(Futures(futures).expire() >= now);     
        
        LogOrder(futures, DataAPI(dataContract).order_id(), DataAPI(dataContract).BUY(), DataAPI(dataContract).NEW(), size, price);    
        
        uint rest = BuyLoop(futures, size, price);   
        if (rest > 0) DataAPI(dataContract).setOrder(futures, msg.sender, DataAPI(dataContract).BUY(), rest, price);
        
        DataAPI(dataContract).IncreaseId();
        return true;
    }
    
    function Sell(address futures, uint size) public returns (bool) {
        require(futures != address(0));
        require(Futures(futures).trade());   
        require(Futures(futures).expire() >= now);        
        require(Futures(futures).balanceOf(msg.sender) >= size.mul(uint(10)**decimals));
        
        LogOrder(futures, DataAPI(dataContract).order_id(), DataAPI(dataContract).SELL(), DataAPI(dataContract).NEW(), size, 0);      
        
        uint rest = SellLoop(futures, size, 0);
        if (rest > 0) LogOrder(futures, DataAPI(dataContract).order_id(), DataAPI(dataContract).SELL(), DataAPI(dataContract).DELETED(), rest, 0);      

        DataAPI(dataContract).IncreaseId();
        return true;
    }

    function SellLimit(address futures, uint size, uint price) public returns (bool) {
        require(futures != address(0));
        require(Futures(futures).trade());   
        require(Futures(futures).expire() >= now);     
        
        LogOrder(futures, DataAPI(dataContract).order_id(), DataAPI(dataContract).SELL(), DataAPI(dataContract).NEW(), size, price);    
        
        uint rest = SellLoop(futures, size, price);   
        if (rest > 0) DataAPI(dataContract).setOrder(futures, msg.sender, DataAPI(dataContract).SELL(), rest, price);
        
        DataAPI(dataContract).IncreaseId();
        return true;
    }
    
    function BuyLoop(address futures, uint size, uint price) internal returns (uint) {
        uint idx = DataAPI(dataContract).findAsk(futures, size, price);
        if (idx == 0) return size;
        
        
        var (_size, _price, _maker, _id) = DataAPI(dataContract).getOrder(futures, idx);
        
        uint part_size = size.min256(_size);
        uint cost = Futures(futures).getCost(part_size);
        
        require(cost > 0);
        
        asyncRequest(msg.sender, cost);
        asyncRequest(msg.sender, cost.mul(taker_fee).div(100000));
        
        LogOrder(futures, DataAPI(dataContract).order_id(), DataAPI(dataContract).BUY(), DataAPI(dataContract).DONE(), part_size, _price);
        
        asyncSend(_maker, cost);
        asyncRequest(_maker, cost.mul(maker_fee).div(100000));
        
        DataAPI(dataContract).DecreaseOrder(futures, _id, part_size);
        LogOrder(futures, _id, DataAPI(dataContract).SELL(), DataAPI(dataContract).DONE(), part_size, _price);  
        
        asyncSend(owner, cost.mul(maker_fee).div(100000).add(cost.mul(taker_fee).div(100000)));
        Futures(futures).transferFrom(_maker, msg.sender, part_size.mul(uint(10)**decimals));
        
        if (size > part_size) return BuyLoop(futures, size - part_size, price);
    }
    
    function SellLoop(address futures, uint size, uint price) internal returns (uint) {
        uint idx = DataAPI(dataContract).findBid(futures, size, price);
        if (idx == 0) return size;
        
        var (_size, _price, _maker, _id) = DataAPI(dataContract).getOrder(futures, idx);
        
        uint part_size = size.min256(_size);
        uint cost = Futures(futures).getCost(part_size);
        
        require(cost > 0);
        
        asyncSend(msg.sender, cost);
        asyncRequest(msg.sender, cost.mul(taker_fee).div(100000));
        
        LogOrder(futures, DataAPI(dataContract).order_id(), DataAPI(dataContract).SELL(), DataAPI(dataContract).DONE(), part_size, _price);
        
        asyncRequest(_maker, cost);
        asyncRequest(_maker, cost.mul(maker_fee).div(100000));
        
        DataAPI(dataContract).DecreaseOrder(futures, _id, part_size);
        LogOrder(futures, _id, DataAPI(dataContract).BUY(), DataAPI(dataContract).DONE(), part_size, _price);  
        
        asyncSend(owner, cost.mul(maker_fee).div(100000).add(cost.mul(taker_fee).div(100000)));
        Futures(futures).transferFrom(msg.sender, _maker, part_size.mul(uint(10)**decimals));
        if (size > part_size) return SellLoop(futures, size - part_size, price);
    }    
    
    function getFuturesListLength() public view returns (uint)
    {
        return DataAPI(dataContract).getFuturesListLength();
    }
    
    function getFuturesByIdx(uint idx) public view returns (address)
    {
        return DataAPI(dataContract).getFuturesByIdx(idx);
    }
    
    function setDataContract(address _dataContract) public onlyOwner returns (bool){
        require(_dataContract != address(0));
        dataContract = _dataContract;
        return true;
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
