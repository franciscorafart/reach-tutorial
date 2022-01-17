import { loadStdlib } from '@reach-sh/stdlib';
import * as backend from './build/index.main.mjs'; // backend that reach compile will produce
const stdlib = loadStdlib(process.env);

/// NOTE: Continue at setting Alice's wager
(async () => {
    const startingBalance = stdlib.parseCurrency(100);
    // These endowments only work on the Reach testing network
    const accAlice = await stdlib.newTestAccount(startingBalance);
    const accBob = await stdlib.newTestAccount(startingBalance);

    const fmt = (x) => stdlib.formatCurrency(x, 4);
    const getBalance = async (who) => fmt(await stdlib.balanceOf(who));
    const beforeAlice = await getBalance(accAlice);
    const beforeBob = await getBalance(accBob);

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
            wager: stdlib.parseCurrency(5),
        }),
        ctcBob.p.Bob({
            ...Player('Bob'),
            acceptWager: (amt) => {
                console.log(`Bob accepts the wager of ${fmt(amt)}`);
            }
        }),
    ]);

    const afterAlice = await getBalance(accAlice);
    const afterBob = await getBalance(accBob);

    console.log(`Alice went from ${beforeAlice} to ${afterAlice}.`);
    console.log(`Bob went from ${beforeBob} to ${afterBob}`);
})();