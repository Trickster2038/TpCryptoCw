pragma solidity ^0.8.0;

import "./CRNL.sol";

// simplier constructor fo CRNL
contract liteCRNL is CRNL {
    constructor (uint128 maxNum_, uint256 betSize_, uint startTime_, uint phaseDuration_) 
        CRNL(maxNum_, true, betSize_, betSize_, betSize_ / 10, betSize_ / 10, 100,
        startTime_, phaseDuration_, phaseDuration_, phaseDuration_) {}
}