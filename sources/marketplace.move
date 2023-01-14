
module maxi::marketplace {

    use std::string::String;

    use sui::object::{UID, ID};
    use sui::sui::SUI;
    use sui::table::Table;
    use sui::coin::Coin;
    use sui::tx_context::TxContext;

    use maxi::safe::{Safe, TransferCap};
    use maxi::collection::RoyaltyReceipt;

    /// A share object holding NFT listing
    struct Marketplace {
        /// NFT's listed for sale in this marketplace, indexed by their id's
        listings: Table<ID, Listing>,
        // commission taken on each filled listing. a flat fee, for simplicity.
        commission: u64
    }

    struct Listing has store {
        /// Price of the item in SUI
        price: u64,
        /// Capability to pull the item out of the appropriate `Safe` when making a sale
        transfer_cap: TransferCap
    }

    fun init(ctx: &mut TxContext) {
        // share the marketplace object, set the initial commission
    }

    public fun list(transfer_cap: TransferCap, marketplace: &mut Marketplace) {
        // create a listing from transfer_cap add it to marketplace
        abort(0)
    }

    public fun buy<T: key + store>(
        royalty: RoyaltyReceipt<T>, coin: &mut Coin<SUI>, id: ID, safe: &mut Safe<T>, marketplace: &mut Marketplace
    ): T {
        // ...extract marketplace.commission from coin
        // ... extract the Listing for ID, get the TransferCap out of it
        // safe::buy_nft(transfer_cap, royalty, id, safe);
        abort(0)
    }
}