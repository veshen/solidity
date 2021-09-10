```
 function (<paramter types>) 
        { private | internal | external public }
        [ pure | constant | view | payable ]
        [ returns(<return types>) ]
    
```

1.private  不能继承、不能够被外部调用
2.internal 可以继承、可以在内部被调用、不能够被外部调用、
3.external 可以继承、不能够在内部调用、可以在外部调用 如果强行调用需要this.xxx()
4.public   可以继承、内部外部都可以调用

1.pure 不会读取全局变量、不会修改全局变量、固定输入 固定输出
2.constant 在函数中和view相同 在全局变量中只用于uint int string bytes1~byte32、代表数据不能被修改
3.view 只读取全局变量的值 不修改全局变量 不消耗gas
4.payable 转账时必须要加的关键字

returns 函数可以有多返回值