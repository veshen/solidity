// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
    映射
 */

contract mappingTest{

    mapping(address => uint) idMapping;
    mapping(uint => string) nameMapping;

    uint num = 0;

    function register(string memory name)
        public
    {
        num++;
        address account = msg.sender;
        idMapping[account] = num;
        nameMapping[num] = name;
    }

    function getIdByAddress(address adds)
        public
        view
        returns(uint)
    {
        return idMapping[adds];
    }


    function getNameById(uint id)
        public
        view
        returns(string)
    {
        return nameMapping[id];
    }

}