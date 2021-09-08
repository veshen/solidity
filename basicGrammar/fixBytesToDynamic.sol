// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
    固定长度字节数组转动态长度字节数组
 */
contract ChangeFixBytes{

    bytes6 public name = 'veshen';

    function changeBytes()
        public
        view
        returns(bytes memory)
    {
        bytes memory newName = new bytes(name.length);
        for (uint256 index = 0; index < name.length; index++) {
            newName[index] = name[index];
        }
        return newName;
    }

}