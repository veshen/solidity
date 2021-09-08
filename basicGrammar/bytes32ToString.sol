// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
    固定字节数组转string
 */
contract Bytes32ToString{

    bytes32 public name = 'veshen';

    function translateByteToString()
        public
        view
        returns(string memory)
    {

        //在函数里使用bytes的时候 加 memory
        bytes memory newName = new bytes(name.length);
        for (uint256 index = 0; index < name.length; index++) {
            newName[index] = name[index];
        }
        return string(newName);
    }

}