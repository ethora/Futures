pragma solidity ^0.4.18;

contract EthOraAPI {
    function insert(int64 _key, int _value) external constant returns (bool replaced);
    function get(int64 _key) external constant returns (uint64 key, int value);
    function getLast() external constant returns (uint64 key, int value);
    function getFirst() external constant returns (uint64 key, int value);
    function getPeriod() public constant returns (uint);
    function getReputation(address issuer) public constant returns (int);
}
