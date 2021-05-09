pragma solidity ^0.8.0;

contract CRDL{
    struct Purchase {
        uint256 n1;
        uint256 n2; 
        uint256 secret;
        bytes secret_b;
        uint256 hashval;
    }

    Purchase public hashstr;

    constructor () {
    }

    function hashPair(uint128 n1_, uint128 n2_) public{
        hashstr.n1 = uint256(n1_);
        hashstr.n2 = uint256(n2_);
        hashstr.secret = uint256((1<<255) + (hashstr.n1<<128) + hashstr.n2);
        hashstr.secret_b = abi.encodePacked(hashstr.secret);
        hashstr.hashval = uint256(sha256(hashstr.secret_b));
    }
}