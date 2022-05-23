//[assignment] write your own unit test to show that your Mastermind variation circuit is working as expected

const { expect } = require("chai");
const chai = require("chai");
const path = require("path")
const wasm_tester = require("circom_tester").wasm;
const F1Field = require("ffjavascript").F1Field;
const Scalar = require("ffjavascript").Scalar;
exports.p = Scalar.fromString("21888242871839275222246405745257275088548364400416034343698204186575808495617");
const Fr = new F1Field(exports.p);
const buildPoseidon = require("circomlibjs").buildPoseidon
const assert = chai.assert;


describe("MasterMind Variation", async function(){
    let poseidon;
    let F;
    this.timeout(1000000);

    before(async ()=>{
        poseidon = await buildPoseidon();
        F=poseidon.F
    })


    it("Should verify proof",async()=>{
        const circuit = await wasm_tester(path.join(__dirname, '..' ,"contracts" ,"circuits", "MastermindVariation.circom"));
        await circuit.loadConstraints()
        const randomsalt= "8762638271"
        const hash=poseidon([randomsalt,1,4,6,7])//calculate hash of salt and numbers

        //input to generate proof
        const INPUT={
            'FirstNumberGuess':"1",
            'SecondNumberGuess':"4",
            'ThirdNumberGuess':"6",
            'FourthNumberGuess':"7",
            'pubNumWhites':"0",
            'pubNumBlacks':"4",
            'pubSolnHash':F.toObject(hash),
            'privSalt':randomsalt,
            'FirstNumber':"1",
            'SecondNumber':"4",
            'ThirdNumber':"6",
            'FourthNumber':"7",
        }

        const witness=await circuit.calculateWitness(INPUT,true)
        await circuit.assertOut(witness,{
            'FirstNumberGuess':"1",
            'SecondNumberGuess':"4",
            'ThirdNumberGuess':"6",
            'FourthNumberGuess':"7",
            'pubNumWhites':"0",
            'pubNumBlacks':"4",
            'pubSolnHash':F.toObject(hash),
            'GuessSolnHash':F.toObject(hash)
        })
    })

    it("Should not verify proof",async()=>{
        let e 
        try {
            const circuit = await wasm_tester(path.join(__dirname, '..' ,"contracts" ,"circuits", "MastermindVariation.circom"));
            await circuit.loadConstraints()
            const randomsalt= "8762638271"
            const hash=poseidon([randomsalt,1,4,6,7])//calculate hash of salt and numbers
            const hash2=poseidon([randomsalt,4,2,5,7])
            //input to generate proof
            const INPUT={
                'FirstNumberGuess':"4",
                'SecondNumberGuess':"2",
                'ThirdNumberGuess':"5",
                'FourthNumberGuess':"7",
                'pubNumWhites':"1",
                'pubNumBlacks':"1",
                'pubSolnHash':F.toObject(hash),
                'privSalt':randomsalt,
                'FirstNumber':"1",
                'SecondNumber':"4",
                'ThirdNumber':"6",
                'FourthNumber':"7",
            }
    
            const witness=await circuit.calculateWitness(INPUT,true)
            await circuit.assertOut(witness,{
                'FirstNumberGuess':"4",
                'SecondNumberGuess':"2",
                'ThirdNumberGuess':"5",
                'FourthNumberGuess':"7",
                'pubNumWhites':"1",
                'pubNumBlacks':"1",
                'pubSolnHash':F.toObject(hash),
                'GuessSolnHash':F.toObject(hash)
            })
        } catch (error) {
                e=error
                expect(e.message).to.be.equal("Error: Assert Failed. Error in template MastermindVariation_77 line: 122")
        }
    })
})

