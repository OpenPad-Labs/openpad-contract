const { JsonRpcProvider, devnetConnection, Ed25519Keypair, RawSigner, LocalTxnDataSerializer } = require("@mysten/sui.js");
const { mnemonic }  = require('./secrets.json');


const path = "m/44'/784'/0'/0'/0'";
const keypair = Ed25519Keypair.deriveKeypair(mnemonic, path);

console.log(keypair.getPublicKey().toSuiAddress());

const provider = new JsonRpcProvider(devnetConnection);

async function main() {
    //await provider.requestSuiFromFaucet(address);
    const signer = new RawSigner(
        keypair,
        provider
    );
    const result = await signer.signAndExecuteTransaction({
        kind: 'moveCall',
        data: {
            packageObjectId: '0xa901063762dcf953ff2a0d08767903436f3fb483',
            module: 'collection',
            function: 'batch_create_artwork_to_project',
            typeArguments: [],
            arguments: [
                '0x75203afe0077667cd77bb291c7fbb1b703f60afe',
                '0x0b752b205b2c80b7fc3c9e5d5edaf751cafcc0b6',
                ['photo1', 'photo2', 'photo3', 'photo4', 'photo5', 'photo6', 'photo7', 'photo8', 'photo9', 'photo10'],
                ['file1', 'file2', 'file3', 'file4', 'file5', 'file6', 'file7', 'file8', 'file9', 'file10'],
                ['name1', 'name2', 'name3', 'name4', 'name5', 'name6', 'name7', 'name8', 'name9', 'name10'],
                ['desc1', 'desc2', 'desc3', 'desc4', 'desc5', 'desc6', 'desc7', 'desc8', 'desc9', 'desc10'],
            ],
            gasBudget: 10000,
        },
    });
    console.log(result);
}

main().catch(console.error);
