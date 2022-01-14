import { loadStdlib } from '@reach-sh/stdlib';
import * as backend from './build/index.main.mjs'; // backend that reach compile will produce
const stdlib = loadStdlib(process.env);

(async () => {
    const startingBalance = stdlib.parseCurrency(100);
    
    // These endowments only work on the Reach testing network
    const accAlice = await stdlib.newTestAccount(startingBalance);
    const accBob = await stdlib.newTestAccount(startingBalance);

    const ctcAlice = accAlice.contract(backend); // deploy application for Alice
    const ctcBob = accBob.contract(backend, ctcAlice.getInfo()); // Attach Bob to application

    const HAND = ['Rock', 'Paper', 'Scissors'];
    const OUTCOME = ['Bob Wins', 'Draw', 'Alice Wins'];

    const Player = (Who) => ({
        getHand: () => {
            const hand = Math.floor(Math.random() * 3);
            console.log(`${Who} played ${HAND[hand]}`);
            return hand;
        },
        setOutcome: (outcome) => {
            console.log(`${Who} saw outcome ${OUTCOME[outcome]}`);
        }
    });


    // intialize backends
    // These are the objects that will bound to the 'interact' in the Reach program
    await Promise.all([
        ctcAlice.p.Alice({
            ...Player('Alice'),
        }),
        ctcBob.p.Bob({
            ...Player('Bob'),
        }),
    ])
})();