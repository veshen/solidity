// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
    send
        调用递归深度不能超过1024
        如果gas不够，执行会失败
        所以使用这个方法要检查成功与否 通过返回值bool来判断
        transfer相对send较安全
    transfer 
 */