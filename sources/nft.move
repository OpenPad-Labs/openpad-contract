
module maxi::nft {

    use std::string::String;
    // use std::vector;

    use sui::object::{Self, UID, ID};
    // use sui::object_table::ObjectTable;
    use sui::sui::SUI;
    use sui::coin::Coin;
    use sui::tx_context::{Self, TxContext};
    use sui::url::Url;
    use sui::transfer;
    use sui::event::emit;

    use maxi::collection::{Self, Collection, MintCap, RoyaltyCap, CollectionProof, RoyaltyReceipt};
    use sui::pay;
    use std::vector;

    /// the nft itself
    struct MaxiNFT has key, store {
        id: UID,
        /// Proof that this NFT belongs to `collection`
        collection: CollectionProof,
        /// metadata understood by the "display" standard goes here
        name: String,
        description: String,
        url: Url,
        // ... more fields
        // ..., or alternatively, we could put the "standard" metadata in a common structure like
        // https://github.com/Origin-Byte/nft-protocol/blob/main/sources/nft/std_nft.move#L22 and
        // ask folks to use this

    }

    /// The mint policy. This is a shared object that allows someone to mint an NFT by paying the required fee.
    /// In all likelihood, there would be libraries for common drop schemes, auctions, etc. that NFT creators can leverage.
    /// But a creator can also define a totally custom policy using arbitrary Move code (e.g., only someone that owns a
    /// JellyNFT can mint a PeanutButterNFT, ...)
    struct MintPolicy has key {
        id: UID,
        mint_cap: MintCap,
        /// Price of the NFT, in SUI
        price: u64,
    }

    /// The royalty policy. This is a shared object that allows a buyer to complete a sale by
    /// complying with it.
    /// In all likelihood, there would be libraries for common policies that NFT creators can
    /// leverage. But a creator can also define a totally custom policy using arbitrary Move code
    /// (e.g., the royalty payment must be half SUI and half DOGE, ...)
    struct RoyaltyPolicy has key {
        id: UID,
        royalty_cap: RoyaltyCap,
        /// Amount to collect on each sale. Use a fixed price here for simplicity, almost
        /// certainly a fraction in practice
        royalty_amount: u64,
        /// total value collected in royalties
        total_collected: u64,
        /// total number of NFT's sold
        total_sales: u64,
        /// these addresses split each royalty payment that comes in
        beneficiaries: vector<address>,
    }

    struct Witness has drop {}

    // events
    struct MaxiNFTCreatedEvent has copy, drop {
        nft_id: ID,
        collection_id: ID,
        name: String,
        description: String,
        url: Url,
    }

    fun init(_ctx: &mut TxContext) {
        // let name = string::utf8(b"Example");
        // let total_supply = 50;
        // let price = 1000;
        // let (collection, mint_cap, royalty_cap) = collection::create<Witness>(&Witness{}, name, total_supply, ctx);
        // transfer::share_object(MintPolicy { id: object::new(ctx), mint_cap, price });
        // transfer::share_object(RoyaltyPolicy { id: object::new(ctx), royalty_amount: 100, total_collected: 0, total_sales: 0, royalty_cap, beneficiaries: vector::singleton(tx_context::sender(ctx))});
        // transfer::freeze_object(collection);
    }

    public entry fun airdrop(
        project: &mut Collection,
        ctx: &mut TxContext
    ) {
        let id = object::new(ctx);
        let nft_id = object::uid_to_inner(&id);

        let (collection_id, collection_proof, name, description, url) =
            collection::mint_airdrop(project, nft_id, ctx);

        let maxiNft = MaxiNFT{
            id,
            collection: collection_proof,
            name,
            description,
            url
        };

        transfer::transfer(maxiNft, tx_context::sender(ctx));

        emit(MaxiNFTCreatedEvent {
            nft_id,
            collection_id,
            name,
            description,
            url,
        });
    }

    public entry fun presale(
        payment: &mut Coin<SUI>,
        project: &mut Collection,
        num: u64,
        ctx: &mut TxContext
    ) {
        while (num > 0) {
            presale_(payment, project, ctx);
            num = num - 1;
        };
    }

    public entry fun public_sale(
        payment: &mut Coin<SUI>,
        project: &mut Collection,
        num: u64,
        ctx: &mut TxContext
    ) {
        while (num > 0) {
            public_sale_(payment, project, ctx);
            num = num - 1;
        };
    }

    public entry fun presale_mul_coin(
        payments: vector<Coin<SUI>>,
        project: &mut Collection,
        num: u64,
        ctx: &mut TxContext
    ){
        let paid = vector::pop_back(&mut payments);
        pay::join_vec(&mut paid, payments);
        presale(&mut paid, project, num, ctx);
        transfer::transfer(paid, tx_context::sender(ctx))
    }

    public entry fun public_sale_mul_coin(
        payments: vector<Coin<SUI>>,
        project: &mut Collection,
        num: u64,
        ctx: &mut TxContext
    ){
        let paid = vector::pop_back(&mut payments);
        pay::join_vec(&mut paid, payments);
        public_sale(&mut paid, project, num, ctx);
        transfer::transfer(paid, tx_context::sender(ctx))
    }

    fun presale_(
        payment: &mut Coin<SUI>,
        project: &mut Collection,
        ctx: &mut TxContext
    ) {
        // MaxiNFT {
        //     id: object::new(ctx),
        //     collection: collection::mint(&mut policy.mint_cap),
        //     // ...deduct policy.price from `payment
        //     // ...derive name and Url from collection
        // }
        let id = object::new(ctx);
        let nft_id = object::uid_to_inner(&id);

        // let collection_id = collection::collection_id(project);
        // let collection_proof = collection::new_collectionProof(project);

        let (collection_id, collection_proof, name, description, url) =
            collection::mint_presale(payment, project, nft_id, ctx);

        let maxiNft = MaxiNFT{
            id,
            collection: collection_proof,
            name,
            description,
            url
        };

        transfer::transfer(maxiNft, tx_context::sender(ctx));

        emit(MaxiNFTCreatedEvent {
            nft_id,
            collection_id,
            name,
            description,
            url,
        });
    }

    fun public_sale_(
        payment: &mut Coin<SUI>,
        project: &mut Collection,
        ctx: &mut TxContext
    ) {

        let id = object::new(ctx);
        let nft_id = object::uid_to_inner(&id);

        // let collection_id = collection::collection_id(project);
        // let collection_proof = collection::new_collectionProof(project);

        let (collection_id, collection_proof, name, description, url) =
            collection::mint_public_sale(payment, project, nft_id, ctx);

        let maxiNft = MaxiNFT{
            id,
            collection: collection_proof,
            name,
            description,
            url
        };

        transfer::transfer(maxiNft, tx_context::sender(ctx));

        emit(MaxiNFTCreatedEvent {
            nft_id,
            collection_id,
            name,
            description,
            url,
        });
    }

    public fun buy(_policy: &mut RoyaltyPolicy, _payment: &mut Coin<SUI>, _ctx: &mut TxContext): RoyaltyReceipt<MaxiNFT> {
        // let receipt = collection::create_receipt(&policy.royalty_cap);
        // // deduct policy.amount from payment, split, send to policy.benificiaries
        // receipt

        abort(0)
    }
}