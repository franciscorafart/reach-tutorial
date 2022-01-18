'reach 0.1';

const [isHand, ROCK, PAPER, SCISSOR ] = makeEnum(3);
const [isOutcome, B_WINS, DRAW, A_WINS] = makeEnum(3);

const winner = (handAlice, handBob) => (handAlice + (4 - handBob)) % 3

assert(winner(ROCK, PAPER) == B_WINS);
assert(winner(PAPER, ROCK) == A_WINS);
assert(winner(PAPER, SCISSOR) == B_WINS);
assert(winner(ROCK, ROCK) == DRAW);

// Proof of theorem using symbolic execution engine (Not trying out every possible value for input params)
forall(UInt, handAlice => 
    forall(UInt, handBob =>
        assert(isOutcome(winner(handAlice, handBob)))));

forall(UInt, hand => assert(winner(hand, hand) == DRAW));

const Player = {
    ...hasRandom, // Adds has random to the interface that the Reach program expects from the front end
    getHand: Fun([], UInt),
    setOutcome:Fun([UInt], Null),
    informTimeout:Fun([], Null),
};

export const main = Reach.App(() => {
    const Alice = Participant('Alice', {
        ...Player, // 'intract' will be bound to the methods defined in this object
        wager: UInt,
        deadline: UInt, // time delta (blocks / rounds)
    });

    const Bob = Participant('Bob', {
        ...Player,
        acceptWager: Fun([UInt], Null),
    });
    init();

    const informTimeout = () => {
        each([Alice, Bob], () => {
            interact.informTimeout();
        });
    };

    Alice.only(() => { // Only Alice performs
        const wager = declassify(interact.wager);
        const _handAlice = interact.getHand(); // compute hand but not declassify it (So Bob can't see it)
        
        // *** Important: makeCommitment allows to publish data, but also keep it secret
        const [_commitAlice, _saltAlice] = makeCommitment(interact, _handAlice)
        const commitAlice = declassify(_commitAlice);
        const deadline = declassify(interact.deadline);
    });

    Alice.publish(wager, commitAlice, deadline).pay(wager); // Alice joins the application, the consensus network
    commit();

    unknowable(Bob, Alice(_handAlice, _saltAlice)); // Makes sure _handAlice and _saltAlice are not visible to Bob at this point in the code

    Bob.only(() => {
        interact.acceptWager(wager);
        const handBob = declassify(interact.getHand());
    })

    Bob.publish(handBob)
        .pay(wager)
        // Timeour handler. If bob times out  after 'deadline', then applications transitions to arrow function
        // closeTo transfers all funds in the contract to the participant passed into the params
        .timeout(relativeTime(deadline), () => closeTo(Alice, informTimeout));
    commit();

    Alice.only(() => {
        const saltAlice = declassify(_saltAlice);
        const handAlice = declassify(_handAlice);
    });

    Alice.publish(saltAlice, handAlice)
        .timeout(relativeTime(deadline), () => closeTo(Bob, informTimeout));

    checkCommitment(commitAlice, saltAlice, handAlice);

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