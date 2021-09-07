 // SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
    固定数组
    固定数组长度无法被修改
 */
contract FixArray{
    
    uint[5] public arr = [1,2,3,4,5];

    function getArray()
        public
        view
        returns(uint[5] memory)
    {
        return arr;
    }

    function init() 
        public
    {
        arr[0] = 100;        
        arr[2] = 200;        
    }

    function getGrade()
        public
        view
        returns(uint)
    {
        uint total = 0;
        for (uint256 index = 0; index < arr.length; index++) {
            total += arr[index];
        }
        return total;
    }

}