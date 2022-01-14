'reach 0.1';

const Player = {
    getHand: Fun([], UInt),
    setOutcome:Fun([UInt], Null),
};

export const main = Reach.App(() => {
    const Alice = Participant('Alice', {
        ...Player, // 'intract' will be bound to the methods defined in this object
    });

    const Bob = Participant('Bob', {
        ...Player,
    });
    init();

    Alice.only(() => { // Only Alice performs
        const handAlice = declassify(interact.getHand()); // Calls front end function
    });

    Alice.publish(handAlice); // Alice joins the application, the consensus network
    commit();

    Bob.only(() => {
        const handBob = declassify(interact.getHand());
    })

    Bob.publish(handBob);
    // Calculate the outcome before commiting
    const outcome = (handAlice+ (4 - handBob)) % 3;

    commit();

    each([Alice, Bob], () => {
        interact.setOutcome(outcome);
    })
});