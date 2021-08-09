//! account: alice ,0xeE337598EAEd6b2317C863aAf3870948, 20000000000 0x1::STC::STC
//! account: bob,1 0x1::STC::STC
//! sender: alice
address alice = {{alice}};
script {
    use 0x1::Token;
    use 0xeE337598EAEd6b2317C863aAf3870948::Doge;
use 0xeE337598EAEd6b2317C863aAf3870948::DogeScript;
    fun test_init(sender: signer) {
        DogeScript::initialize_script( sender);
        let market_cap = Token::market_cap<Doge::SHIBA>();
        assert(market_cap == 0, 8001);
        assert(Token::is_registered_in<Doge::SHIBA>(@alice), 8002);
    }
}
// check: "Keep(EXECUTED)"
//! new-transaction
//! sender: bob
address bob = {{bob}};
script {
    use 0x1::Account;
    use 0xeE337598EAEd6b2317C863aAf3870948::Doge;

    use 0xeE337598EAEd6b2317C863aAf3870948::DogeScript;

    fun test_mint(sender: signer) {
        DogeScript::mint_script(sender,100000);
        let balance = Account::balance<Doge::SHIBA>(@bob);
        assert(100000 == balance, 1);
    }
}
// check: "Keep(EXECUTED)"

