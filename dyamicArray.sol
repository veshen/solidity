 // SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
    动态长度数组
    可以修改length
    有push方法
 */
contract DyamicArray{
    
    uint[] public arr = [1,2,3,4,5];

    string[] public arr2 = ['a'];

    function getArray()
        public
         view
        returns(uint[] memory)
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