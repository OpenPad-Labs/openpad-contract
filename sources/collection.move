
module maxi::collection {

    use std::string::String;
    use std::option::{Option};

    use sui::object::{Self, UID, ID};
    use sui::object_table::{Self as ot, ObjectTable};
    
    // use sui::table::Table;
    use sui::vec_map::{Self, VecMap};
    use std::vector;
    use sui::event::emit;
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    use sui::balance::{Self, Balance};
    use sui::sui::SUI;
    use sui::url::Url;
    use sui::coin::{Self, Coin};
    use sui::object_table;
    // use sui::math::min;

    struct Collection has key, store {
        id: UID,
        // Standard fields that every collection needs go here
        // but more will be needed

        /// Address that created this collection
        creator: address,
        // Name of the collection. TODO: should be this just be t.name?
        name: String,
        slogan: String,
        /// Description of the collection
        description: String,
        /// the maximum number of the instantiated NFT objects. Use U64_MAX if there is no max
        total_supply: u64,
        // ... more standard fields
        icon: vector<u8>,
        cover_photo: vector<u8>,
        team: String,
        roadmap: String,
        royalty: u64,
        twitter: Option<String>,
        discord: Option<String>,
        website: Option<String>,
        telegram: Option<String>,
        artwork_placeholder: vector<u8>,
        artworks: ObjectTable<u64, Artwork>,    // (artwork idx, artwork)
        photo_onchain: bool,
        art_sequence: u64,
        minted: VecMap<address, u64>,   // record a address and minted number, (address, artwork numbers)
        created_at: u64,

        profits: Balance<SUI>
        // Custom metadata outside of the standard fields goes here
        // custom_metadata: M,
    }

    /// Proof that the given NFT is one of the limited `total_supply` NFT's in `Collection`
    struct CollectionProof has store {
        collection_id: ID
    }

    struct Artwork has key, store {
        id: UID,
        photo: vector<u8>,
        attribute: Attribute,
    }

    struct ArtworkStore has key {
        id: UID,
        name: String,   // use project name
        artworks: ObjectTable<u64, Artwork>,
        sequence: u64,
        length: u64,
    }

    struct ArtwrokField has store, copy, drop {
        photo: vector<u8>,
        filename: String,
        name: String,
        description: String,
        background: Option<String>,
    }

    struct Attribute has store, copy, drop {
        filename: String,
        name: String,
        description: String,
        background: Option<String>,
    }
    
    struct Whitelist has key, store {
        id: UID,
        collection_id: ID,
        listed: VecMap<address, Eligibility>,     // record a address can mint number
        minted: VecMap<u64, MintedTime>    // record the artwork mint by addres, (artwork_idx, address)
    }

    struct Eligibility has store, copy, drop {
        num: u64,
        price: u64,
        deadline: u64,
    }

    struct MintedTime has store, copy, drop {
        owner: address,
        minted_at: u64,
    }

    // events
    struct ArtwrokCreatedEvent has copy, drop {
        art_id: ID,
        photo: vector<u8>,
        attribute: Attribute,
    }

    struct CollectionCreatedEvent has copy, drop {
        collection_id: ID,
        creator: address,
        name: String,
        total_supply: u64,
        created_at: u64,
    }

    // errors
    const EArtworks_Too_Large: u64 = 10001;
    const EArtwork_Field_Length_Invalid: u64 = 10002;
    const ENoProfits: u64 = 10003;
    const EInsufficientFunds: u64 = 10004;
    const EMintTooMany: u64 = 10005;
    const ENotMarchWhiteList: u64 = 10006;
    const ENotMarchCollection: u64 = 10007;
    const EDeadLine: u64 = 10008;
    const EArtWorkIdx: u64 = 10009;
    const EMaxTotalSupply: u64 = 10010;

    struct ManageCap has key {
        id: UID,
    }

    /// Grants the permission to mint `num_remaining` NFT's of type `T`
    /// The sum of `num_remaining` for all mint caps + the number of instantiated
    /// NFT's should be equal to `total_supply`.
    /// This is a fungible type to support parallel minting, giving a buyer the permission
    /// mint themselves, allowing multiple parties to mint, and so on.
    struct MintCap has key, store {
        id: UID,
        /// ID of the collection that this MintCap corresponds to
        collection: ID,
        /// Number of NFT's this cap can mint
        num_remaining: u64,
    }

    struct CollectCap has key, store {
        id: UID,
        /// ID of the collection that this MintCap corresponds to
        collection: ID,
    }

    /// Grants the permission to mint `RoyaltyReceipt`'s for `T`.
    /// Receipts are required when paying for NFT's
    struct RoyaltyCap has key, store {
        id: UID,
        collection: ID,
    }

    /// Proof that the royalty policy for collection `T` has been satisfied.
    /// Needed to complete a sale of an NFT from a Collection<T>`
    struct RoyaltyReceipt<phantom T> {
        id: UID,
        collection: ID,
    }

    fun init(ctx: &mut TxContext) {

        transfer::transfer(ManageCap{id:object::new(ctx)},
            tx_context::sender(ctx));
    }

    /// Instantiate a collection for T.
    /// To be called from the module initializer in the module that declares `T`
    public entry fun new_collection(
        // _witness: &T,
        _cap: &ManageCap,
        creator: address,
        name: String,
        slogan: String,
        description: String,
        icon: vector<u8>,
        cover_photo: vector<u8>,
        team: String,
        roadmap: String,
        total_supply: u64,
        royalty: u64,
        twitter: Option<String>,
        discord: Option<String>,
        website: Option<String>,
        telegram: Option<String>,
        artwork_placeholder: vector<u8>,
        photo_onchain: bool,
        ctx: &mut TxContext,
    ) {
        let id = object::new(ctx);
        let collection_id = object::uid_to_inner(&id);
        let created_at = tx_context::epoch(ctx);
        let artworks = ot::new(ctx);

        let collection = Collection {
            id,
            creator,
            name,
            slogan,
            description,
            icon,
            cover_photo,
            team,
            roadmap,
            total_supply,
            royalty,
            twitter,
            discord,
            website,
            telegram,
            artwork_placeholder,
            artworks,
            art_sequence: 0,
            minted: vec_map::empty(),
            photo_onchain,
            created_at,
            profits: balance::zero<SUI>()
        };

        let mint_cap = MintCap {
            id: object::new(ctx),
            collection: collection_id,
            num_remaining: total_supply,
        };

        let collect_cap = CollectCap {
            id: object::new(ctx),
            collection: collection_id,
        };

        let royalty_cap = RoyaltyCap {
            id: object::new(ctx),
            collection: collection_id,
        };


        emit(CollectionCreatedEvent {
            collection_id,
            creator,
            name,
            total_supply,
            created_at,
        });

        transfer::share_object(collection);
        transfer::transfer(mint_cap, creator);
        transfer::transfer(collect_cap, creator);
        transfer::transfer(royalty_cap, creator);
    }

    // new a artwork and return
    public fun new_artwork(
        photo: vector<u8>,
        filename: String,
        name: String,
        description: String,
        background: Option<String>,
        ctx: &mut TxContext,
    ): Artwork {
        let attribute = Attribute {
            filename, name, description, background,
        };
        let id = object::new(ctx);
        let art_id = object::uid_to_inner(&id);

        let artwork = Artwork {
            id,
            photo,
            attribute,
        };

        emit(ArtwrokCreatedEvent {
            art_id,
            photo,
            attribute,
        });

        artwork
    }


    // add artworks to a collection
    // Performance Optimization Fix: artworks will is desc order
    public entry fun add_artworks_to_project(
        _cap: &ManageCap, 
        collection: &mut Collection, 
        artworks: vector<Artwork>
    ) {
        
        let artworks_len = vector::length(&artworks);
        assert!(collection.total_supply >= artworks_len, EArtworks_Too_Large);

        vector::reverse(&mut artworks);
        let idx = 0;

        while (idx < artworks_len) {
            let artwork = vector::pop_back(&mut artworks);
            ot::add(&mut collection.artworks, idx, artwork);
            idx = idx + 1;
        };
        
        vector::destroy_empty(artworks);
    }

    public entry fun create_artwork(
        photo: vector<u8>,
        filename: String,
        name: String,
        description: String,
        background: Option<String>,
        ctx: &mut TxContext,
    ) {
        let artwork = new_artwork(photo, filename, name, description, background, ctx);

        transfer::transfer(artwork, tx_context::sender(ctx));
    }

    // create a store to list the artworks
    public entry fun create_artwork_store(name: String, ctx: &mut TxContext) {
        let id = object::new(ctx);
        let store = ArtworkStore {
            id,
            name,
            artworks: ot::new(ctx),
            sequence: 0,
            length: 0,
        };

        transfer::transfer(store, tx_context::sender(ctx));
    }

    // sdk can retreive all artworks with store
    public entry fun add_artwork_to_store(store: &mut ArtworkStore, artwork: Artwork) {
        let idx = artworks_sequence(store);
        ot::add(&mut store.artworks, idx, artwork);
        store.sequence = store.sequence + 1;
        store.length = store.length + 1;
    }

    // public entry fun batch_create_artwork_to_project(project: &mut Collection, values: vector<ArtwrokField>, ctx: &mut TxContext) {
    //     let artworks = batch_new_artwork(values, ctx);
    //     add_artworks_to_project(project, artworks);
    // }

    // create the artwork use the fields in ordering,
    public entry fun batch_create_artwork_to_project(
        cap: &ManageCap,
        project: &mut Collection,
        photos: vector<vector<u8>>,
        filenames: vector<String>,
        names: vector<String>,
        descriptions: vector<String>,
        backgrounds: vector<Option<String>>,
        ctx: &mut TxContext,
    ) {
        let filename_len = vec_len(&filenames);
        assert!(vec_len(&photos) == filename_len, EArtwork_Field_Length_Invalid);
        assert!(filename_len == vec_len(&names), EArtwork_Field_Length_Invalid);
        assert!(filename_len == vec_len(&descriptions), EArtwork_Field_Length_Invalid);
        assert!(filename_len == vec_len(&backgrounds), EArtwork_Field_Length_Invalid);

        // vector::reverse(&mut photos);
        // vector::reverse(&mut filenames);
        // vector::reverse(&mut names);
        // vector::reverse(&mut descriptions);
        // vector::reverse(&mut backgrounds);

        let desc_fields = vector::empty();
        while (!vector::is_empty(&filenames)) {
            let field = ArtwrokField {
                photo: pop_back(&mut photos),
                filename: pop_back(&mut filenames),
                name: pop_back(&mut names),
                description: pop_back(&mut descriptions),
                background: pop_back(&mut backgrounds),
            };
            vector::push_back(&mut desc_fields, field);
        };

        let artworks = batch_new_artwork(desc_fields, ctx);

        add_artworks_to_project(cap, project, artworks);
    }

    // new a whitelist 
    public entry fun create_whitelist(
        _cap: &ManageCap,
        whitelist: vector<address>,
        _project: &mut Collection,
        num: u64,
        price: u64,
        deadline: u64,
        ctx: &mut TxContext
    ) {
        let listed = vec_map::empty();

        while (!vector::is_empty(&whitelist)) {
            vec_map::insert(&mut listed, pop_back(&mut whitelist), Eligibility { num, price, deadline });
        };

        let whitelist = Whitelist {
            id: object::new(ctx),
            collection_id: object::uid_to_inner(&_project.id),
            listed,
            minted: vec_map::empty(),
        };

        transfer::share_object(whitelist);
    }

    // add addresses to a Whitelist // TODO
    public entry fun add_address_to_whitelist(
        _cap: &ManageCap,
        _whitelist: &mut Whitelist,
        _addresses: vector<address>,
        num: u64,
        price: u64,
        deadline: u64
    ) {

        while (!vector::is_empty(&_addresses)) {
            vec_map::insert(&mut _whitelist.listed, pop_back(&mut _addresses), Eligibility { num, price, deadline });
        };
    }

    // user mint // TODO
    public fun mint(
        payment: Coin<SUI>,
        _project: &mut Collection,
        whitelist: &mut Whitelist,
        _ctx: &mut TxContext
    ): (ID, CollectionProof, String, Url) {

        let sender = tx_context::sender(_ctx);
        let epoch = tx_context::epoch(_ctx);

        assert!(object::uid_to_inner(&_project.id) == whitelist.collection_id, ENotMarchCollection);

        assert!(vec_map::contains(&whitelist.listed, &sender), ENotMarchWhiteList);

        let eligibility = vec_map::get(&whitelist.listed, &tx_context::sender(_ctx));

        assert!(eligibility.deadline > epoch, EDeadLine);

        //update collection profits
        let payment_balance = coin::into_balance(payment);
        assert!(balance::value(&payment_balance) == eligibility.price, EInsufficientFunds);
        balance::join( &mut _project.profits, payment_balance);

        //update collection art_sequence
        let artWork_idx = _project.art_sequence;
        assert!(object_table::length(&_project.artworks) > artWork_idx, EArtWorkIdx);
        let artWork = object_table::borrow(&_project.artworks, artWork_idx);
        _project.art_sequence = artWork_idx + 1;

        //update collection minted
        let minted = 0;
        if (vec_map::contains(&_project.minted, &sender)){
            // minted = vec_map::get_mut(&mut _project.minted, &sender);
            (_, minted) = vec_map::remove(&mut _project.minted, &sender);
        };
        minted = minted + 1;
        vec_map::insert(&mut _project.minted, sender, minted);

        //check whiteList
        assert!(eligibility.num >= minted, EMintTooMany);
        vec_map::insert(&mut whitelist.minted, artWork_idx, MintedTime{owner: sender, minted_at: epoch});

        //check total supply
        assert!(vec_map::size(&whitelist.minted)<= _project.total_supply, EMaxTotalSupply);

        (collection_id(_project), new_collectionProof(_project), artwork_name(artWork), artwork_url(artWork))
    }

    // airdrop claim // TODO
    public entry fun airdrop_claim(_project: &mut Collection, _ctx: &mut TxContext) {

    }

    // release given project, and then user call mint 
    // Notice: create a new Project because sui share object MUST in create object function
    public entry fun release_collection(
        _cap: &ManageCap,
        collection: Collection,
        whitelist: Whitelist,
        ctx: &mut TxContext,
    ) {
        let Collection {
            id,
            name,
            creator,
            slogan,
            description,
            icon,
            cover_photo,
            team,
            roadmap,
            total_supply,
            royalty,
            twitter,
            discord,
            website,
            telegram,
            artwork_placeholder,
            artworks,
            art_sequence,
            minted,
            photo_onchain,
            created_at,
            profits,
        } = collection;

        let collection_to_share = Collection {
            id: object::new(ctx),
            name,
            creator,
            slogan,
            description,
            icon,
            cover_photo,
            team,
            roadmap,
            total_supply,
            royalty,
            twitter,
            discord,
            website,
            telegram,
            artwork_placeholder,
            artworks,
            art_sequence,
            minted,
            photo_onchain,
            created_at,
            profits,
        };

        transfer::share_object(collection_to_share);
        transfer::share_object(whitelist);
        object::delete(id);
    }

    public entry fun collect_profits(
        _cap: &CollectCap,
        collection: &mut Collection,
        ctx: &mut TxContext
    ) {

        let amount = balance::value( & collection.profits);
        assert!(amount > 0, ENoProfits);
        let coin = coin::take( &mut collection.profits, amount, ctx);
        transfer::transfer(coin, tx_context::sender(ctx));
    }

    // Internal functions

    // use the desc order field to create asc Artwork.
    public fun batch_new_artwork(desc_values: vector<ArtwrokField>, ctx: &mut TxContext): vector<Artwork> {
        let artworks = vector::empty();

        while (vector::is_empty(&desc_values)) {
            let field = vector::pop_back(&mut desc_values);
            let artwork = new_artwork(field.photo, field.filename, field.name, field.description, field.background, ctx);
            vector::push_back(&mut artworks, artwork);
        };

        artworks
    }

    public fun remove_artwork_from_store(store: &mut ArtworkStore, idx: u64): Artwork {
        let artwork = ot::remove(&mut store.artworks, idx);
        store.length = store.length - 1;

        artwork
    }
    
    // Getters
    public fun artworks_length(artworks: &ArtworkStore): u64 {
        artworks.length
    }

    public fun artworks_sequence(artworks: &ArtworkStore): u64 {
        artworks.sequence
    }

    public fun collection_id(collection: &Collection): ID {
        object::uid_to_inner(&collection.id)
    }

    public fun artwork_name(artwork: &Artwork): String {
        artwork.attribute.name
    }

    public fun artwork_url(artwork: &Artwork): Url {
        sui::url::new_unsafe_from_bytes(artwork.photo)
    }

    public fun vec_len<T>(vec: &vector<T>): u64 {
        vector::length<T>(vec)
    }

    fun pop_back<T>(vec: &mut vector<T>): T {
        vector::pop_back(vec)
    }

    /// To be called from the module that declares `T`, when packing a value of type `T`.
    /// The caller should place the `CollectionProof` in a field of `T`.
    /// Decreases `num_remaining` by `amount`
    // public fun mint(mint_cap: &mut MintCap): CollectionProof {
    //     abort(0)
    // }
    public fun new_collectionProof(_project: &Collection): CollectionProof{
        let collectionProof = CollectionProof {
            collection_id: object::uid_to_inner(&_project.id),
        };

        collectionProof
    }

    /// To be called from the module that declares `T`.
    /// The caller is responsible for gating usage of the `royalty_cap` with its
    /// desired royalty policy.
    public fun create_receipt<T>(royalty_cap: &mut RoyaltyCap): RoyaltyReceipt<T> {
        abort(0)
    }

    /// Split a big `mint_cap` into two smaller ones
    public fun split<T>(mint_cap: &mut MintCap, num: u64): MintCap {
        abort(0)
    }

    /// Combine two `MintCap`'s
    public fun join<T>(mint_cap: &mut MintCap, to_join: MintCap) {
        abort(0)
    }
}