pragma circom 2.0.0;

// [assignment] implement a variation of mastermind from https://en.wikipedia.org/wiki/Mastermind_(board_game)#Variation as a circuit


/*
    This variation of mastermind would require you to guess 4 unique numbers between 0 and 9 whose sum amount to 18.
    A white color is for when you guess a number right and not the position.
    A black color is for when you guess the number and position right.

*/

include "../../node_modules/circomlib/circuits/comparators.circom";
include "../../node_modules/circomlib/circuits/bitify.circom";
include "../../node_modules/circomlib/circuits/poseidon.circom";

template MastermindVariation() {
    // Public inputs
    signal input FirstNumberGuess;
    signal input SecondNumberGuess;
    signal input ThirdNumberGuess;
    signal input FourthNumberGuess;
    signal input pubNumWhites;
    signal input pubNumBlacks;
    signal input pubSolnHash;

    //private input
    signal input privSalt;
    signal input FirstNumber;
    signal input SecondNumber;
    signal input ThirdNumber;
    signal input FourthNumber;

    //output
    signal output GuessSolnHash;


    var guessSoln[4]=[FirstNumberGuess,SecondNumberGuess,ThirdNumberGuess,FourthNumberGuess];
    var correctSoln[4]=[FirstNumber,SecondNumber,ThirdNumber,FourthNumber];

    var numWhite=0;
    var numBlack=0;

    component lessThan[8];
    //circom doesnt respect scoping
    var j=0;
    var k=0;
    component equalGuess[6];
    component equalSoln[6];
    var equalIdx=0;

    //constraint to make sure all guess input and solution input is less than 10
    for(j=0;j<4;j++){
        lessThan[j]=LessThan(4);
        lessThan[j + 4]=LessThan(4);
        //check for guess solution
        lessThan[j].in[0]<==guessSoln[j];
        lessThan[j].in[1]<==10;
        //check for correct solution
        lessThan[j+4].in[0]<==correctSoln[j];
        lessThan[j+4].in[1]<==10;

        for(k=j+1;k<4;k++){
            //creates constraints that makes each number unique
            equalGuess[equalIdx] = IsEqual();
            equalGuess[equalIdx].in[0] <== guessSoln[j];
            equalGuess[equalIdx].in[1] <== guessSoln[k];
            equalGuess[equalIdx].out === 0;
            equalSoln[equalIdx] = IsEqual();
            equalSoln[equalIdx].in[0] <== correctSoln[j];
            equalSoln[equalIdx].in[1] <== correctSoln[k];
            equalSoln[equalIdx].out === 0;
            equalIdx += 1;
        }
    }
    var sumSoln=FirstNumber+SecondNumber+ThirdNumber+FourthNumber;
    var sumGuess=FirstNumberGuess+SecondNumberGuess+ThirdNumberGuess+FourthNumberGuess;

    //assert that sum is specified sum
    assert(sumSoln == 18);
    assert(sumGuess == 18);

    //count black and white
    component equalMatch[16];


    for(j=0;j<4;j++){
        for(k=0;k<4;k++){
            equalMatch[4*j+k]=IsEqual();
            equalMatch[4*j+k].in[0] <== correctSoln[j];
            equalMatch[4*j+k].in[1] <== guessSoln[k];
            numWhite += equalMatch[4*j+k].out;
            if(j==k){
                //if position and number match add to balck subtract from white
                numBlack += equalMatch[4*j+k].out;
                numWhite -= equalMatch[4*j+k].out;
            }

        }
    }


    //create constraint for white and black indicator
    component equalWhite=IsEqual();
    equalWhite.in[0] <-- pubNumWhites;
    equalWhite.in[1] <-- numWhite;
    equalWhite.out === 1;
    
    component equalBlack=IsEqual();
    equalBlack.in[0] <-- pubNumBlacks;
    equalBlack.in[1] <-- numBlack;
    equalBlack.out === 1;

    component poseidon=Poseidon(5);
    poseidon.inputs[0]<==privSalt;
    poseidon.inputs[1]<==FirstNumberGuess;
    poseidon.inputs[2]<==SecondNumberGuess;
    poseidon.inputs[3]<==ThirdNumberGuess;
    poseidon.inputs[4]<==FourthNumberGuess;

    GuessSolnHash<==poseidon.out;
    pubSolnHash === GuessSolnHash;


}

component main {public [FirstNumberGuess,SecondNumberGuess,ThirdNumberGuess,FourthNumberGuess,pubNumBlacks,pubNumWhites,pubSolnHash]} = MastermindVariation();