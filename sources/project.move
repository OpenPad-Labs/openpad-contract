
// Project Information

module maxi::project {

    // use std::vector;
    use sui::object::{Self, ID, UID};
    use std::option::{Option};
    use std::string::{String};
    use sui::tx_context::{Self, TxContext};
    use sui::vec_map::{Self, VecMap};
    // use sui::sui::SUI;
    use sui::transfer;
    use sui::event::emit;
    use std::vector;
    use sui::object_table::{Self as ot, ObjectTable};

    struct ProjectProfile has key, store {
        id: UID,
        collection_name: String,
        collection_slogan: String,
        collection_desc: String,
        icon: vector<u8>,
        cover_photo: vector<u8>,
        team: String,
        roadmap: String,
        supply: u64,
        royalty: u64,
        twitter: Option<String>,
        discord: Option<String>,
        website: Option<String>,
        telegram: Option<String>,
        wallet_addr: address,
        artwork_placeholder: vector<u8>,
        artworks: ObjectTable<u64, Artwork>,    // (artwork idx, artwork)
        photo_onchain: bool,
        art_sequence: u64,
        minted: VecMap<address, u64>,   // record a address and minted number, (address, artwork numbers)
        created_at: u64,
    }

    struct ManageCap has key {
        id: UID,
    }

    struct ArtworkStore has key {
        id: UID,
        name: String,   // use project name
        artworks: ObjectTable<u64, Artwork>,
        sequence: u64,
        length: u64,
    }

    struct Artwork has key, store {
        id: UID,
        photo: vector<u8>,
        attribute: Attribute,
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
    struct ProjectCreatedEvent has copy, drop {
        project_id: ID,
        collection_name: String,
        collection_slogan: String,
        collection_desc: String,
        icon: vector<u8>,
        cover_photo: vector<u8>,
        team: String,
        roadmap: String,
        supply: u64,
        royalty: u64,
        twitter: Option<String>,
        discord: Option<String>,
        website: Option<String>,
        telegram: Option<String>,
        wallet_addr: address,
        artwork_placeholder: vector<u8>,
        photo_onchain: bool,
        created_at: u64,
    }

    // events
    struct ArtwrokCreatedEvent has copy, drop {
        art_id: ID,
        photo: vector<u8>,
        attribute: Attribute,
    }

    // errors
    const EArtworks_Too_Large: u64 = 10001;
    const EArtwork_Field_Length_Invalid: u64 = 10002;

    // init module
    fun init(ctx: &mut TxContext) {
        init_module(ctx);
    }

    fun init_module(ctx: &mut TxContext) {
        transfer::transfer(ManageCap { id: object::new(ctx) }, tx_context::sender(ctx));
    }

    // new a project and emit created event, and return project
    public fun new_project(
        collection_name: String,
        collection_slogan: String,
        collection_desc: String,
        icon: vector<u8>,
        cover_photo: vector<u8>,
        team: String,
        roadmap: String,
        supply: u64,
        royalty: u64,
        twitter: Option<String>,
        discord: Option<String>,
        website: Option<String>,
        telegram: Option<String>,
        wallet_addr: address,
        artwork_placeholder: vector<u8>,
        photo_onchain: bool,
        ctx: &mut TxContext,
    ): ProjectProfile {
        let id = object::new(ctx);
        let project_id = object::uid_to_inner(&id);
        let created_at = tx_context::epoch(ctx);
        let artworks = ot::new(ctx);

        let project = ProjectProfile {
            id,
            collection_name,
            collection_slogan,
            collection_desc,
            icon,
            cover_photo,
            team,
            roadmap,
            supply,
            royalty,
            twitter,
            discord,
            website,
            telegram,
            wallet_addr,
            artwork_placeholder,
            artworks,
            art_sequence: 0,
            minted: vec_map::empty(),
            photo_onchain,
            created_at,
        };

        emit(ProjectCreatedEvent { 
            project_id,
            collection_name,
            collection_slogan,
            collection_desc,
            icon,
            cover_photo,
            team,
            roadmap,
            supply,
            royalty,
            twitter,
            discord,
            website,
            telegram,
            wallet_addr,
            artwork_placeholder,
            photo_onchain,
            created_at,          
        });

        project
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

    // create project and send to caller
    public entry fun create_project(
        collection_name: String,
        collection_slogan: String,
        collection_desc: String,
        icon: vector<u8>,
        cover_photo: vector<u8>,
        team: String,
        roadmap: String,
        supply: u64,
        royalty: u64,
        twitter: Option<String>,
        discord: Option<String>,
        website: Option<String>,
        telegram: Option<String>,
        wallet_addr: address,
        artwork_placeholder: vector<u8>,
        photo_onchain: bool,
        ctx: &mut TxContext,
    ) {
        let project = new_project(
            collection_name,
            collection_slogan,
            collection_desc,
            icon,
            cover_photo,
            team,
            roadmap,
            supply,
            royalty,
            twitter,
            discord,
            website,
            telegram,
            wallet_addr,
            artwork_placeholder,
            photo_onchain,
            ctx,
        );

        transfer::transfer(project, tx_context::sender(ctx));
    }

    // add artworks to a project
    // Performance Optimization Fix: artworks will is desc order
    public entry fun add_artworks_to_project(
        _cap: &ManageCap, 
        project: &mut ProjectProfile, 
        artworks: vector<Artwork>
    ) {
        
        let artworks_len = vector::length(&artworks);
        assert!(project.supply >= artworks_len, EArtworks_Too_Large);

        vector::reverse(&mut artworks);
        let idx = 0;

        while (idx < artworks_len) {
            let artwork = vector::pop_back(&mut artworks);
            ot::add(&mut project.artworks, idx, artwork);
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

    // public entry fun batch_create_artwork_to_project(project: &mut ProjectProfile, values: vector<ArtwrokField>, ctx: &mut TxContext) {
    //     let artworks = batch_new_artwork(values, ctx);
    //     add_artworks_to_project(project, artworks);
    // }

    // create the artwork use the fields in ordering,
    public entry fun batch_create_artwork_to_project(
        cap: &ManageCap,
        project: &mut ProjectProfile,
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
    public entry fun create_whitelist(whitelist: vector<address>, num: u64, price: u64, deadline: u64, ctx: &mut TxContext) {
        let listed = vec_map::empty();

        while (!vector::is_empty(&whitelist)) {
            vec_map::insert(&mut listed, pop_back(&mut whitelist), Eligibility { num, price, deadline });
        };

        let whitelist = Whitelist {
            id: object::new(ctx),
            listed,
            minted: vec_map::empty(),
        };

        transfer::transfer(whitelist, tx_context::sender(ctx));
    }

    // add addresses to a Whitelist // TODO
    public entry fun add_address_to_whitelist(_cap: &ManageCap, _whitelist: &mut Whitelist, _addresses: vector<address>) {
        
    }

    // user mint // TODO
    public entry fun mint(_project: &mut ProjectProfile, _ctx: &mut TxContext) {

    }

    // airdrop claim // TODO
    public entry fun airdrop_claim(_project: &mut ProjectProfile, _ctx: &mut TxContext) {

    }

    // release given project, and then user call mint 
    // Notice: create a new Project because sui share object MUST in create object function
    public entry fun release_project(
        _cap: &ManageCap,
        project: ProjectProfile,
        whitelist: Whitelist,
        ctx: &mut TxContext,
    ) {
        let ProjectProfile {
            id,
            collection_name,
            collection_slogan,
            collection_desc,
            icon,
            cover_photo,
            team,
            roadmap,
            supply,
            royalty,
            twitter,
            discord,
            website,
            telegram,
            wallet_addr,
            artwork_placeholder,
            artworks,
            art_sequence,
            minted,
            photo_onchain,
            created_at,
        } = project;

        let project_to_share = ProjectProfile {
            id: object::new(ctx),
            collection_name,
            collection_slogan,
            collection_desc,
            icon,
            cover_photo,
            team,
            roadmap,
            supply,
            royalty,
            twitter,
            discord,
            website,
            telegram,
            wallet_addr,
            artwork_placeholder,
            artworks,
            art_sequence,
            minted,
            photo_onchain,
            created_at,
        };

        transfer::share_object(project_to_share);
        transfer::share_object(whitelist);
        object::delete(id);
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

    public fun vec_len<T>(vec: &vector<T>): u64 {
        vector::length<T>(vec)
    }

    fun pop_back<T>(vec: &mut vector<T>): T {
        vector::pop_back(vec)
    }
}