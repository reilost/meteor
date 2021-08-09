address 0xeE337598EAEd6b2317C863aAf3870948 {
module Doge {
    use 0x1::Account;
    use 0x1::Token ;

    struct SHIBA has copy, drop, store {}

    const PRECISION: u8 = 9;

    struct SharedMintCapability has key, store {
        cap: Token::MintCapability<SHIBA>,
    }

    struct SharedBurnCapability has key, store {
        cap: Token::BurnCapability<SHIBA>,
    }

    public(script) fun initialize(account:&signer) {
        Token::register_token<SHIBA>(account, PRECISION);
        Account::do_accept_token<SHIBA>(account);
        let mint_cap = Token::remove_mint_capability<SHIBA>(account);
        move_to(account, SharedMintCapability { cap: mint_cap });
        let burn_cap = Token::remove_burn_capability<SHIBA>(account);
        move_to(account, SharedBurnCapability { cap: burn_cap });
    }

    public fun mint(amount: u128): Token::Token<SHIBA>
    acquires SharedMintCapability {
        let cap = borrow_global<SharedMintCapability>(@0xeE337598EAEd6b2317C863aAf3870948);
        Token::mint_with_capability<SHIBA>(
        & cap.cap,
        amount
        )
    }
}
}
