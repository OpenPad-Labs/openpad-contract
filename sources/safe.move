
module maxi::safe {
    
    use std::string::String;

    use sui::object::{UID, ID};
    use sui::object_table::ObjectTable;
    use sui::table::Table;
    use sui::vec_set::VecSet;
    use sui::tx_context::TxContext;

    /// A shared object for storing NFT's of type `T`, owned by the holder of an unique `OwnerCap`.
    /// Permissions to allow others to list NFT's can be granted via TransferCap's and BorrowCap's
    struct Safe<phantom T: key + store> has key {
        id: UID,
        /// NFT's in this safe, indexed by their ID's
        nfts: ObjectTable<ID, T>,
        /// For easier naming/ retriveal of NFT's, range is a subset of domain of `nfts`
        nickname: Table<String, ID>,
        /// ID's of NFT's that are currently listed for sale. There can only be borrowed immutablely
        listed: VecSet<ID>,
        /// ID's of `NFT` that are currenty borrowed. These cannot be listed for sale while borrowing is active
        borrowed: VecSet<ID>,
        /// Valid version for transferCap's
        transfer_cap_version: u64,
        /// Valid version for borrowCap's
        borrow_cap_version: u64,
        /// If true, anyone can place NFT's into this safe.
        /// If false, deposits require the OwnerCap.
        accept_deposit: bool,
    }

    /// A unique capability held by the owner of a particular `Safe`
    /// The holder can issue and revoke `TransferCap`'s and `BorrowCap`'s
    /// Can be used an arbitrary number of times
    struct OwnerCap has key, store {
        id: UID,
        /// The ID of the safe that this capability grants permission to
        safe_id: ID,
        /// version of this cap.
        version: u64,
    }

    /// Gives the holder permission to transfer the nft with id `nft_id` out of 
    /// the safe with id `safe_id`. 
    /// Can only be used once
    struct TransferCap has key, store {
        id: UID,
        /// The ID of the safe that this capability grants permission to
        safe_id: ID,
        /// The ID of the NFT that this capability can transfer
        nft_id: ID,
        version: u64,
    }

    /// Gives the holder permission to borrow the nft with id `nft_id` out of
    /// the safe with id `safe_id`. 
    /// Can be used an arbitrary number of times.
    struct BorrowCap has key, store {
        id: UID,
        /// The ID of the safe that this capability grants permissions to
        safe_id: ID,
        /// The ID of the NFT that this capability can borrow
        nft_id: ID,
        version: u64
    }

    /// "Hot potato" wrapping the borrowed NFT. Must be returned to `safe_id`
    /// before the end of the current transaction
    struct Borrowed<T> {
        nft: T,
        /// The safe that this NFT came from
        safe_id: ID,
        /// If true, only an immutable reference to `nft` can be granted
        /// Always false if the NFT is currently listed
        is_mutable: bool,
    }
    
    struct RoyaltyReceipt<phantom T> {

    }

    /// Create and share a fresh Safe that can hold T's
    /// Return an `OwnerCap` for the Safe
    public fun create<T>(_ctx: &mut TxContext): OwnerCap {
        abort(0)
    }

    /// Produce a `TransferCap` for the NFT with `id` and `safe`.
    /// This `TransferCap` can be (e.g.) used to list the NFT on a marketplace
    public fun sell_nft<T: key + store>(_owner_cap: &OwnerCap, _id: ID, _safe: &mut Safe<T>): TransferCap {
        abort(0)
    }

    /// Consume `cap`, remove the NFT with `id` from `safe`, and return it to the caller.
    /// Requiring `royalty` ensure that the caller has paid the required royatly for this collection
    /// before completing the purchase
    /// This invalidates all other `TransferCap`'s by increasing safe.transfer_cap_version
    public fun buy_nft<T: key + store>(_cap: TransferCap, _royatly: RoyaltyReceipt<T>, _id: ID, _safe: &mut Safe<T>): T {
        abort(0)
    }

    /// Allow the holder of `borrow_cap` to borrow NFT specified in `borrow_cap` from `safe` for the duration
    /// of the current transaction
    public fun borrow_nft<T: key + store>(_borrow_cap: &BorrowCap, _safe: &mut Safe<T>): Borrowed<T> {
        abort(0)
    }

    /// Return the NFT in `borrowed` to the `safe` it came from
    public fun unborrow_nft<T: key + store>(_borrowed: Borrowed<T>, _safe: &mut Safe<T>) {
        abort(0)
    }

    /// Get access
    public fun get_nft_mut<T>(_borrowed: &mut Borrowed<T>): &mut T {
        abort(0)
    }

    public fun get_nft<T>(_borrowed: &Borrowed<T>): &T {
        abort(0)
    }
}