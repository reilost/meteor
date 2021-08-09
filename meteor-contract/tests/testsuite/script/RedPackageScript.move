//! account: alice , 20000000000 0x1::STC::STC
//! account: bob,1 0x1::STC::STC
//! account: jay,1 0x1::STC::STC
//! account: ice,1 0x1::STC::STC
//! sender: alice
script {
    use 0xeE337598EAEd6b2317C863aAf3870948::RedPackageScript;

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
        RedPackageScript::create_script<STC::STC>(sender, root, amount, leafs);
    }
}
// check: "Keep(EXECUTED)"


//! new-transaction
//! sender: bob
address alice = {{alice}};
address bob = {{bob}};
script {
    use 0xeE337598EAEd6b2317C863aAf3870948::RedPackageScript;
    use 0x1::STC;
    use 0x1::Account;

    fun test_claim(sender: signer) {
        let root = b"abcdefg123456";
        RedPackageScript::claim_script<STC::STC>(sender,@alice, root);
        let balance = Account::balance<STC::STC>(@bob);
        assert(1000000000 + 1 == balance, 1);
    }
}
// check: "Keep(EXECUTED)"