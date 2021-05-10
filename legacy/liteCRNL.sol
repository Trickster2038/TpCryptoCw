pragma solidity ^0.8.0;

import "./CRNL.sol";

contract liteCRNL is CRNL {
    uint t;
    constructor (uint128 maxNum_, uint256 betSize_, uint startTime_, uint phaseDuration_) 
        CRNL(maxNum_, betSize_, 
        startTime_, phaseDuration_) public {}
        //maxNum_, true, betSize_, betSize_, betSize_, betSize_, 100, startTime_, 
        //phaseDuration_, phaseDuration_, phaseDuration_
}