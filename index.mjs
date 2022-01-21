import { loadStdlib } from '@reach-sh/stdlib';
import * as backend from './build/index.main.mjs'; // backend that reach compile will produce
import {ask, yesno, done } from '@reach-sh/stdlib/ask.mjs';
const stdlib = loadStdlib(process.env);

(async () => {
    // NOTE: To deply on algo testnet set REACH_CONNECTOR_MODE=ALGO-live on the terminal for both participants
    stdlib.setProviderByName('TestNet');

    const isAlice = await ask(
        'Are you Alice', 
        yesno,
    );

    const who = isAlice ? 'Alice' :  'Bob';

    console.log(`Starting Rock, Paper, Scissors as ${who}`);


    const secret = await ask(
        'What is your current mnemonic?',
        (x => x)
    );
    const acc = await stdlib.newAccountFromMnemonic(secret);
    

    let ctc = null
    if (isAlice) {
        ctc = acc.contract(backend);
        ctc.getInfo().then(info => {
            console.log(`The contract is deployed as ${JSON.stringify(info)}`);
        });
    } else {
        const info = await ask(
            'Please paste the contract information',
            JSON.parse,
        );
        ctc = acc.contract(backend, info);
    }

    const fmt = (x) => stdlib.formatCurrency(x, 4);
    const getBalance = async () => fmt(await stdlib.balanceOf(acc));
    
    const before = await getBalance();
    console.log(`Your balance  is ${before}`);

    const interact = {...stdlib.hasRandom};

    // const ctcAlice = accAlice.contract(backend); // deploy application for Alice
    // const ctcBob = accBob.contract(backend, ctcAlice.getInfo()); // Attach Bob to application

    interact.informTimeout = () => {
        console.log('There was a timout');
        process.exit(1);
    }

    // Define wager amount or acceptWager depending on which use
    if (isAlice) {
        const amt = await ask(
            'How much do you want to wager?',
            stdlib.parseCurrency,
        );

        interact.wager= amt;
        interact.deadline = { ETH: 100, ALGO: 100, CFX: 1000}[stdlib.connector]
    } else { 
        // BOB
        interact.acceptWager= async (amt) => {
            const accepted = await ask(
                `Do you accept the wager of ${fmt(amt)}`,
                yesno
            );

            if (!accepted) {
                process.exit(0);
            }
        }
    }

    const HAND = ['Rock', 'Paper', 'Scissors'];
    const HANDS = {
        'Rock': 0, 'R': 0, 'r': 0,
        'Paper': 1, 'P': 1, 'p': 1,
        'Scissors': 2, 'S': 2, 's': 2,
    };

    interact.getHand = async () => {
        const hand = await ask(`What hand will you play?`, x => {
            const hand = HANDS[x];
            if (hand == null) {
                throw Error(`Not a valid hand ${hand}`) 
            }
            return hand;
        });
        console.log(`You played hand ${HAND[hand]}`);
        return hand;
    }
    
    const OUTCOME = ['Bob Wins', 'Draw', 'Alice Wins'];
    interact.seeOutcome = async outcome => {
        console.log(`The outcome is ${OUTCOME[outcome]}`);
    };

    const part = isAlice ? ctc.p.Alice: ctc.p.Bob;
    await part(interact);

    const after = await getBalance();
    console.log(`Your balance is now ${after}`);

    done();
})();