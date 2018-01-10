pragma solidity ^0.4.18;

import "./Futures.sol";
import "./FuturesExchToken.sol";
import "./FuturesExchLib.sol";
import "./DataAPI.sol";

contract FuturesExch is FuturesExchToken {
    
    address public dataContract;

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
        uint cost = FuturesExchLib.Buy(futures, size, dataContract);
        if (cost == 0) return false;
        else {
            transfer(this, cost);
            return true;
        }
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
