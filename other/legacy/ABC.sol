pragma solidity ^0.8.0;

contract ABC {
    address public owner1;
    uint private gg; 
    constructor(uint gg_){
        owner1 = msg.sender;
        gg = gg_;
    }
}