#[test_only]
module maxi::collection_tests {

    #[test_only]
    use sui::test_scenario::{Self};

    use maxi::collection::{Self, ManageCap, Collection, MintCap};
    use maxi::nft::{Self};
    use std::debug;
    use std::string::{Self, String};
    use std::vector;
    use sui::coin;
    use sui::sui::SUI;

    const OWNER: address = @0xA1C05;
    const CREATOR: address = @0xA1C01;
    const FAKE_OWNER: address = @0xA1C04;


    const WHITELIST1: address = @0xA1C11;
    const WHITELIST2: address = @0xA1C12;
    const WHITELIST3: address = @0xA1C13;
    const WHITELIST4: address = @0xA1C14;
    const WHITELIST5: address = @0xA1C15;

    #[test]
    fun create_collection(){


        let scenario_val = test_scenario::begin(OWNER);
        let scenario = &mut scenario_val;

        // init module
        let ctx = test_scenario::ctx(scenario);
        collection::init_test(ctx);

        test_scenario::next_tx(scenario, OWNER); {
            let manCap = test_scenario::take_from_sender<ManageCap>(scenario);
            debug::print(&manCap);

            let ctx = test_scenario::ctx(scenario);
            collection::new_collection(
                &manCap,
                CREATOR,
                string::utf8(b"James"),
                string::utf8(b"James slogan"),

                string::utf8(b"James description"),
                b"icon",
                b"cover_photo",
                string::utf8(b"team"),
                string::utf8(b"roadmap"),
                10,
                100,
                b"artwork_placeholder",
                true,
                ctx
            );

            test_scenario::return_to_sender<ManageCap>(scenario, manCap);
        };

        test_scenario::next_tx(scenario, CREATOR); {

            let collection_test = test_scenario::take_shared<Collection>(scenario);
            debug::print(&collection_test);


            let mint_cap = test_scenario::take_from_sender<MintCap>(scenario);
            debug::print(&mint_cap);


            let collect_cap = test_scenario::take_from_sender<collection::CollectCap>(scenario);
            debug::print(&collect_cap);

            let whitelist = test_scenario::take_shared_by_id<collection::Whitelist>(
                scenario,
                collection::whitelist_id_from_collection(&collection_test)
            );
            debug::print(&whitelist);

            test_scenario::return_shared(whitelist);
            test_scenario::return_to_sender(scenario, mint_cap);
            test_scenario::return_to_sender(scenario, collect_cap);
            test_scenario::return_shared<Collection>(collection_test);
        };

        test_scenario::next_tx(scenario, OWNER); {

            let manCap = test_scenario::take_from_sender<ManageCap>(scenario);
            let collection_test = test_scenario::take_shared<Collection>(scenario);
            let whiteList_old = test_scenario::take_shared_by_id<collection::Whitelist>(
                scenario,
                collection::whitelist_id_from_collection(&collection_test)
            );
            debug::print(&whiteList_old);

            let whitelist = vector::empty<address>();
            vector::push_back(&mut whitelist, WHITELIST1);
            vector::push_back(&mut whitelist, WHITELIST2);
            collection::add_address_to_whitelist(
                &manCap,
                &mut whiteList_old,
                whitelist,
                2,
                10,
                25
            );

            debug::print(&whiteList_old);

            test_scenario::return_shared(whiteList_old);
            test_scenario::return_to_sender(scenario, manCap);
            test_scenario::return_shared(collection_test);
        };

        test_scenario::next_tx(scenario, OWNER); {

            let manCap = test_scenario::take_from_sender<ManageCap>(scenario);
            let collection_test = test_scenario::take_shared<Collection>(scenario);

            let photos = vector::empty<vector<u8>>();
            vector::push_back(&mut photos, b"photo1");
            vector::push_back(&mut photos, b"photo2");
            vector::push_back(&mut photos, b"photo3");

            let filenames = vector::empty<String>();
            vector::push_back(&mut filenames, string::utf8(b"filename1"));
            vector::push_back(&mut filenames, string::utf8(b"filename2"));
            vector::push_back(&mut filenames, string::utf8(b"filename3"));

            let names = vector::empty<String>();
            vector::push_back(&mut names, string::utf8(b"name1"));
            vector::push_back(&mut names, string::utf8(b"name2"));
            vector::push_back(&mut names, string::utf8(b"name3"));

            let descriptions = vector::empty<String>();
            vector::push_back(&mut descriptions, string::utf8(b"description1"));
            vector::push_back(&mut descriptions, string::utf8(b"description2"));
            vector::push_back(&mut descriptions, string::utf8(b"description3"));

            let ctx = test_scenario::ctx(scenario);
            collection::batch_create_artwork_to_project(
                &manCap,
                &mut collection_test,
                photos,
                filenames,
                names,
                descriptions,
                ctx
            );

            debug::print(&collection_test);

            test_scenario::return_to_sender(scenario, manCap);
            test_scenario::return_shared(collection_test);
        };

        test_scenario::next_tx(scenario, WHITELIST1); {

            let collection_test = test_scenario::take_shared<Collection>(scenario);
            let whiteList_old = test_scenario::take_shared_by_id<collection::Whitelist>(
                scenario,
                collection::whitelist_id_from_collection(&collection_test)
            );

            let ctx = test_scenario::ctx(scenario);
            nft::mint(
                coin::mint_for_testing<SUI>(10, ctx),
                &mut collection_test,
                &mut whiteList_old,
                ctx
            );

            test_scenario::return_shared(whiteList_old);
            test_scenario::return_shared(collection_test);
        };

        test_scenario::next_tx(scenario, WHITELIST1); {

            let nft = test_scenario::take_from_sender<nft::MaxiNFT>(scenario);
            let collection_test = test_scenario::take_shared<Collection>(scenario);

            debug::print(&nft);
            debug::print(&collection_test);

            test_scenario::return_to_sender(scenario, nft);
            test_scenario::return_shared(collection_test);
        };

        test_scenario::end(scenario_val);
    }

}