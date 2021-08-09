//! account: alice , 20000000000 0x1::STC::STC
//! account: bob,1 0x1::STC::STC
//! account: jay,1 0x1::STC::STC
//! account: ice,1 0x1::STC::STC
//! sender: alice
script {
    use 0xeE337598EAEd6b2317C863aAf3870948::RedPackage;

    use 0x1::STC;
    use 0x1::Vector;

    fun test_create(sender: signer) {
        let root = b"abcdefg123456";
        let amount = 1000000000 * 2;
        let leafs = Vector::empty();
        let i = 0;
        while (i < 2) {
            Vector::push_back(&mut leafs, 1000000000);
            i = i + 1;
        };
        RedPackage::create<STC::STC>(&sender, root, amount, leafs);
    }
}
// check: "Keep(EXECUTED)"

//! new-transaction
//! sender: bob
address alice = {{alice}};
script {
    use 0xeE337598EAEd6b2317C863aAf3870948::RedPackage;
    use 0x1::STC;
    use 0x1::Account;
    use 0x1::Signer;

    fun test_claim(sender: signer) {
        let root = b"abcdefg123456";
        RedPackage::claim<STC::STC>(&sender,@alice, root);

        let ad = Signer::address_of(&sender);
        let balance = Account::balance<STC::STC>(ad);
        assert(1000000000 + 1 == balance, 1);
    }
}
// check: "Keep(EXECUTED)"


//! new-transaction
//! sender: jay
address alice = {{alice}};
script {
    use 0xeE337598EAEd6b2317C863aAf3870948::RedPackage;
    use 0x1::STC;
    use 0x1::Account;
    use 0x1::Signer;

    fun test_claim(sender: signer) {
        let root = b"abcdefg123456";
        RedPackage::claim<STC::STC>(&sender,@alice, root);

        let ad = Signer::address_of(&sender);
        let balance = Account::balance<STC::STC>(ad);
        assert(1000000000 + 1 == balance, 1);
    }
}
// check: "Keep(EXECUTED)"


//! new-transaction
//! sender: bob
address alice = {{alice}};
script {
    use 0xeE337598EAEd6b2317C863aAf3870948::RedPackage;
    use 0x1::STC;

    fun test_claim(sender: signer) {
        let root = b"abcdefg123456";
        RedPackage::claim<STC::STC>(&sender,@alice, root);
    }
}
// check: "Keep(ABORTED { code: 1799,"


//! new-transaction
//! sender: bob
script {
    use 0xeE337598EAEd6b2317C863aAf3870948::RedPackage;

    use 0x1::STC;
    use 0x1::Vector;

    fun test_create(sender: signer) {
        let root = b"abcdefg123";
        let amount = 10000000000;
        let leafs = Vector::empty();
        Vector::push_back(&mut leafs, 1000000000);
        RedPackage::create<STC::STC>(&sender, root, amount, leafs);
    }
}
// check: "Keep(ABORTED { code: 775,"


//! new-transaction
//! sender: bob
script {
    use 0xeE337598EAEd6b2317C863aAf3870948::RedPackage;

    use 0x1::STC;
    use 0x1::Vector;

    fun test_create(sender: signer) {
        let root = b"abcdefg432";
        let amount = 20000000000;
        let leafs = Vector::empty();
        Vector::push_back(&mut leafs, 20000000000);
        RedPackage::create<STC::STC>(&sender, root, amount, leafs);
    }
}
// check: "Keep(ABORTED { code: 1031,"


//! new-transaction
//! sender: bob
address alice = {{alice}};
script {
    use 0xeE337598EAEd6b2317C863aAf3870948::RedPackage;
    use 0x1::STC;

    fun test_claim(sender: signer) {
        let root = b"abcd";
        RedPackage::claim<STC::STC>(&sender,@alice, root);
    }
}
// check: "Keep(ABORTED { code: 1287,"

//! new-transaction
//! sender: ice
address alice = {{alice}};
script {
    use 0xeE337598EAEd6b2317C863aAf3870948::RedPackage;
    use 0x1::STC;
    fun test_claim( sender: signer) {
        let root = b"abcdefg123456";
        RedPackage::claim<STC::STC>(&sender,@alice, root);
    }
}
// check: "Keep(ABORTED { code: 1543,"