# meteor-contract
在这个项目我们简单了实现了一个抢红包的功能和发一个Token,作为一个合约实现演示.

## RedPackage.move
这个合约是红包的实现合约,实现了三个方法,创建红包,领红包和撤销红包
主要使用了 `stdlib` 提供的 `Collection2` 和 `Option`
## Doge.move
这个合约我们发了一个名为 `SHIBA` 的代币完整的合约地址为 `0xeE337598EAEd6b2317C863aAf3870948::Doge::SHIBA`

同时我们对外提供了任何人都可以 `MINT` 的方法

这里主要是展示在一些场景(比如合成资产)如何在调用方没有 `MINT Capability` 的情况下进行 `MINT`

## functional-test
在`tests/testsuite`这个目录下,我们展示了如何做 `functional-test` ,项目目录下执行`move functional-test`即可

## CI
我们使用github action展示了如何进行批量部署合约,

这只是一个demo目的是为了简化在本地和测试网络部署的操作,

**请勿用于主网的合约部署**

