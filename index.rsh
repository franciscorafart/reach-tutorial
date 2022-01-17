'reach 0.1';

const Player = {
    getHand: Fun([], UInt),
    setOutcome:Fun([UInt], Null),
};

export const main = Reach.App(() => {
    const Alice = Participant('Alice', {
        ...Player, // 'intract' will be bound to the methods defined in this object
        wager: UInt,
    });

    const Bob = Participant('Bob', {
        ...Player,
        acceptWager: Fun([UInt], Null),
    });
    init();

    Alice.only(() => { // Only Alice performs
        const wager = declassify(interact.wager);
        const handAlice = declassify(interact.getHand()); // Calls front end function
    });

    Alice.publish(wager, handAlice).pay(wager); // Alice joins the application, the consensus network
    commit();

    Bob.only(() => {
        interact.acceptWager(wager);
        const handBob = declassify(interact.getHand());
    })

    Bob.publish(handBob).pay(wager);

    // Calculate the outcome before commiting
    const outcome = (handAlice+ (4 - handBob)) % 3;
    const [forAlice, forBob] = outcome === 2 ? [2, 0] : outcome == 0 ? [0, 2] : [1, 1];

    transfer(forAlice * wager).to(Alice);
    transfer(forBob * wager).to(Bob);

    commit();

    each([Alice, Bob], () => {
        interact.setOutcome(outcome);
    })
});