address 0xeE337598EAEd6b2317C863aAf3870948 {
module RedPackageScript {

    use 0xeE337598EAEd6b2317C863aAf3870948::RedPackage;

    public(script) fun create_script<TokenType: store>
    (account: signer,
     root: vector<u8>,
     amount: u128,
     leafs: vector<u128>)
    {
        RedPackage::create<TokenType>(&account, root, amount, leafs);
    }

    public(script) fun claim_script<TokenType: store>
    (account: signer,
     owner_address: address,
     root: vector<u8>
    ) {
        RedPackage::claim<TokenType>(&account, owner_address, root);
    }

    public(script) fun cancel_all_script<TokenType: store>
    (account: signer
    ) {
        RedPackage::cancel_all<TokenType>(&account);
    }
}
}
    