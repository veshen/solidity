// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
        以太坊中的全局属性
        msg.sender returns(address) 返回合约调用者的account地址
        block.difficulty returns(uint) 返回当前块的困难度
        block.number uint 当前区块的块号,也就是合约所在区块的块号
        block.coinbase address 当前块矿工的地址
        block.gaslimit uint
        block.timestamp uint 当前块的Unix时间戳
        msg.data bytes 完整的调用数据(calldata)
        msg.sig bytes4 调用数据(calldata)的前四个字节
        msg.value uint 这个消息所附带的以太币，消息为wei
        now uint 当前块的时间戳 == block.timestamp
        tx.gasprice uint 交易的gas价格
        tx.origin address 交易的发送者（全调用链)
 */

contract globalAttr{

    function getGlobalAttr()
        public
        returns(address)
    {
        return msg.sender;
    }

}