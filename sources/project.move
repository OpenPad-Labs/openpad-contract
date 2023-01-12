
// Project Information

module maxi::project {

    // use std::vector;
    use sui::object::{Self, ID, UID};
    use std::option::{Option};
    use std::string::{String};
    use sui::tx_context::{Self, TxContext};
    // use sui::coin::Coin;
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
        artworks: ObjectTable<u64, Artwork>,
        photo_onchain: bool,
        art_sequence: u64,
        minted: u64,
        created_at: u64,
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
    const EArtworks_Too_Large: u64 = 0;

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
            minted: 0,
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
    public entry fun add_artworks_to_project(project: &mut ProjectProfile, artworks: vector<Artwork>) {
        
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

    public entry fun add_artwork_to_store(store: &mut ArtworkStore, artwork: Artwork) {
        let idx = artworks_sequence(store);
        ot::add(&mut store.artworks, idx, artwork);
        store.sequence = store.sequence + 1;
        store.length = store.length + 1;
    }

    public fun batch_new_artwork(values: vector<ArtwrokField>, ctx: &mut TxContext): vector<Artwork> {
        let artworks = vector::empty();

        vector::reverse(&mut values);

        while (vector::is_empty(&values)) {
            let field = vector::pop_back(&mut values);
            let artwork = new_artwork(field.photo, field.filename, field.name, field.description, field.background, ctx);
            vector::push_back(&mut artworks, artwork);
        };

        artworks
    }

    // public entry fun batch_create_artwork_to_project(project: &mut ProjectProfile, values: vector<ArtwrokField>, ctx: &mut TxContext) {
    //     let artworks = batch_new_artwork(values, ctx);
    //     add_artworks_to_project(project, artworks);
    // }

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
}