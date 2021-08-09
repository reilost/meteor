address 0xeE337598EAEd6b2317C863aAf3870948 {
module RedPackage {
    use 0x1::Vector;
    use 0x1::Signer;
    use 0x1::Collection2;
    use 0x1::Account;
    use 0x1::Errors;
    use 0x1::Token ;
    use 0x1::Option::{Option, Self};

    const INSUFFICIENT_AVAILABLE_BALANCE: u64 = 3;
    const INSUFFICIENT_AMOUNT: u64 = 4;
    const REDPACKAGE_NOT_EXISTS: u64 = 5;
    const REDPACKAGE_IS_EMPTY: u64 = 6;
    const ALREADY_CLAIMED: u64 = 7;

    struct RedPackage<TokenType: store> has store {
        merkle_root: vector<u8>,
        tokens: Token::Token<TokenType>,
        leafs: vector<u128>,
        claimed: vector<address>,
    }

    public fun cancel_all<TokenType : store>(account: &signer) {
        let owner_address = Signer::address_of(account);
        let c = Collection2::exists_at<RedPackage<TokenType>>(owner_address);
        assert(c, Errors::invalid_argument(REDPACKAGE_NOT_EXISTS));

        let c = Collection2::borrow_collection<RedPackage<TokenType>>(account, owner_address);
        let c_len = Collection2::length<RedPackage<TokenType>>(&c);
        let i = 0;
        while (i < c_len) {
            let rp = Collection2::remove<RedPackage<TokenType>>(&mut c, 0);
            let amount = Token::value<TokenType>(&rp.tokens);
            let unclaimed_tokens = Token::withdraw(&mut rp.tokens, amount);
            if (amount > 0) {
                Account::deposit_to_self<TokenType>(account, unclaimed_tokens);
            }else {
                Token::destroy_zero<TokenType>(unclaimed_tokens);
            };
            let RedPackage<TokenType> {
                merkle_root: _,
                tokens: coins,
                leafs: _,
                claimed: _,
            } = rp;
            Token::destroy_zero<TokenType>(coins);
            i = i + 1;
        };
        Collection2::return_collection(c);
        Collection2::destroy_collection<RedPackage<TokenType>>(account);
    }


    public fun create<TokenType: store>(account: &signer, merkle_root: vector<u8>,
                                        token_amount: u128, leafs: vector<u128>) {
        let owner_address = Signer::address_of(account);
        let sum = sum(&leafs);
        assert(sum == token_amount, Errors::invalid_argument(INSUFFICIENT_AVAILABLE_BALANCE));

        let token_balance = Account::balance<TokenType>(owner_address);
        assert(token_balance > token_amount, Errors::invalid_argument(INSUFFICIENT_AMOUNT));
        let tokens = Account::withdraw<TokenType>(account, token_amount);
        let redPackage = RedPackage<TokenType> {
            merkle_root,
            tokens,
            leafs,
            claimed: Vector::empty()
        };
        if (!Collection2::exists_at<RedPackage<TokenType>>(owner_address)) {
            Collection2::create_collection<RedPackage<TokenType>>(account, false, true);
        };
        Collection2::put(account, Signer::address_of(account), redPackage);
    }

    public fun claim<TokenType: store>(account: &signer, owner_address: address, merkle_root: vector<u8>) {
        let idx_option = get_airdrop_idx<TokenType>(account, &owner_address, &merkle_root);
        assert(!Option::is_none(&idx_option), Errors::invalid_argument(REDPACKAGE_NOT_EXISTS));
        let c = Collection2::borrow_collection<RedPackage<TokenType>>(account, owner_address);
        let idx = Option::borrow<u64>(&idx_option);
        let red = Collection2::borrow_mut<RedPackage<TokenType>>(&mut c, *idx);
        assert(!address_claimed(red, Signer::address_of(account)), Errors::invalid_argument(ALREADY_CLAIMED));

        assert(!is_empty(red), Errors::invalid_argument(REDPACKAGE_IS_EMPTY));
        let is_accept_token = Account::is_accepts_token<TokenType>(Signer::address_of(account));
        if (!is_accept_token) {
            Account::do_accept_token<TokenType>(account);
        };
        Vector::push_back(&mut red.claimed, Signer::address_of(account));
        let ll = Vector::length(&red.claimed);
        let amount = Vector::borrow(&red.leafs, ll - 1);
        let claimed_tokens = Token::withdraw(&mut red.tokens, *amount);
        Account::deposit_to_self(account, claimed_tokens);
        Collection2::return_collection(c);
    }

    fun is_empty<TokenType: store>(red: &RedPackage<TokenType>): bool {
        Vector::length(&red.leafs) == Vector::length(&red.claimed)
    }

    fun address_claimed<TokenType: store>(red: &RedPackage<TokenType>, address: address): bool {
        Vector::contains(&red.claimed, &address)
    }

    fun get_airdrop_idx<TokenType: store>(account: &signer, owner_address: &address, merkle_root: &vector<u8>): Option<u64> {
        let idx = Option::none<u64>();
        if (Collection2::exists_at<RedPackage<TokenType>>(*owner_address)) {
            let c = Collection2::borrow_collection<RedPackage<TokenType>>(account, *owner_address);
            let c_len = Collection2::length<RedPackage<TokenType>>(&c);
            let i = 0;
            while (i < c_len) {
                let red = Collection2::borrow<RedPackage<TokenType>>(&mut c, i);
                if ( *&red.merkle_root == *merkle_root) {
                    Option::fill(&mut idx, i);
                    break
                };
                i = i + 1;
            };
            Collection2::return_collection(c);
        };
        return idx
    }


    fun sum(leafs: &vector<u128>): u128 {
        let i = 0;
        let sum = 0u128;
        let ll = Vector::length(leafs);
        while (i < ll) {
            let x = *Vector::borrow<u128>(leafs, i);
            sum = x + sum ;
            i = i + 1;
        };
        sum
    }
}
}
    