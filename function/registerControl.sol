// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;



contract mappingTest{

    mapping(address => uint) idMapping;
    mapping(uint => string) nameMapping;

    uint num = 0;

    modifier OnlyOnce(){
        require(idMapping[msg.sender]==0);
        _;
    }

    /**
        注册
     */
    function register(string memory name)
        public
        OnlyOnce
    {
        num++;
        address account = msg.sender;
        idMapping[account] = num;
        nameMapping[num] = name;
    }

    /**
        根据address获取id
     */
    function getIdByAddress(address adds)
        public
        view
        returns(uint)
    {
        return idMapping[adds];
    }

    /**
        通过id获取name
     */
    function getNameById(uint id)
        public
        view
        returns(string memory)
    {
        return nameMapping[id];
    }

}