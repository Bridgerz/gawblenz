module gawblenz::gawblen;

use gawblenz::distribution::Distribution;
use std::string::{Self, String};
use sui::vec_map::VecMap;

/// Total of 3333 Gawblenz
const MAX_ID: u16 = 3333;

/// Tries to burn the cap before minting all the NFTs.
const ENotCompletedProcess: u64 = 1;
/// Mint limit exceeded.
const EMintLimitExceeded: u64 = 2;

public struct GawblenClaimed() has copy, store, drop;

public struct Gawblen has key, store {
    id: UID,
    name: String,
    description: String,
    image_url: String,
    number: u16,
    traits: VecMap<String, String>,
}

public struct AdminCap has key, store {
    id: UID,
    max_id: u16,
    current: u16,
}

fun init(ctx: &mut TxContext) {
    transfer::transfer(
        AdminCap {
            id: object::new(ctx),
            max_id: MAX_ID,
            current: 1,
        },
        ctx.sender(),
    );
}

public fun create(
    cap: &mut AdminCap,
    distribution: &mut Distribution<Gawblen>,
    image_url: String,
    traits: VecMap<String, String>,
    ctx: &mut TxContext,
) {
    assert!(cap.current <= cap.max_id, EMintLimitExceeded);
    let mut name = string::utf8(b"Gawblen #");
    string::append(&mut name, std::u16::to_string(cap.current));

    let description = b"No think. Just Gawblen".to_string();

    let nft = Gawblen {
        id: object::new(ctx),
        name,
        description,
        image_url,
        number: cap.current,
        traits,
    };

    distribution.add_nft(nft);
    cap.current = cap.current + 1;
}

public fun number(gawblenz: &Gawblen): &u16 {
    &gawblenz.number
}

public fun image_url(gawblenz: &Gawblen): String {
    gawblenz.image_url
}

public fun traits(gawblenz: &Gawblen): VecMap<String, String> {
    gawblenz.traits
}

public fun burn_cap(cap: AdminCap) {
    assert!(cap.current > cap.max_id, ENotCompletedProcess);

    let AdminCap { id, .. } = cap;
    id.delete();
}

#[test_only]
public(package) fun init_for_testing(ctx: &mut TxContext) {
    init(ctx);
}

#[test_only]
public(package) fun create_admin_cap_for_testing(
    ctx: &mut TxContext,
): AdminCap {
    AdminCap {
        id: object::new(ctx),
        max_id: MAX_ID,
        current: 1,
    }
}

#[test_only]
public(package) fun max_id(cap: &AdminCap): u16 {
    cap.max_id
}
