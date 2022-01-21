'reach 0.1';

const [isHand, ROCK, PAPER, SCISSORS ] = makeEnum(3);
const [isOutcome, B_WINS, DRAW, A_WINS] = makeEnum(3);

const winner = (handAlice, handBob) => ((handAlice + (4 - handBob)) % 3);

assert(winner(ROCK, PAPER) == B_WINS);
assert(winner(PAPER, ROCK) == A_WINS);
assert(winner(PAPER, SCISSORS) == B_WINS);
assert(winner(ROCK, ROCK) == DRAW);

// Proof of theorem using symbolic execution engine 
// i.e Not trying out every possible value for input params
forall(UInt, handAlice => 
    forall(UInt, handBob =>
        assert(isOutcome(winner(handAlice, handBob)))));

forall(UInt, hand => assert(winner(hand, hand) == DRAW));

const Player = {
    ...hasRandom, // Add hasRandom to the interface that the Reach program expects from the front end
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
        const deadline = declassify(interact.deadline);
    });
    
    Alice.publish(wager, deadline).pay(wager); // Alice joins the application, the consensus network
    commit();
    
    Bob.only(() => {
        interact.acceptWager(wager);
    })
    
    // Timeour handler. If bob times out  after 'deadline', then applications transitions to arrow function
    // closeTo transfers all funds in the contract to the participant passed into the params
    Bob.pay(wager)
        .timeout(relativeTime(deadline), () => closeTo(Alice, informTimeout));
    
    var outcome = DRAW;
    // States invariant portion of the while loop => balance is constant and `outcome` is a valid outcome
    invariant( balance() == 2 * wager && isOutcome(outcome) );
    while (outcome == DRAW) {
        commit();
        
        Alice.only(() => {
            const _handAlice = interact.getHand(); // compute hand but not declassify it (So Bob can't see it)
            
            // *** Important: makeCommitment allows to publish data, but also keep it secret
            const [_commitAlice, _saltAlice] = makeCommitment(interact, _handAlice)
            const commitAlice = declassify(_commitAlice);
        });
        
        Alice.publish(commitAlice)
            .timeout(relativeTime(deadline), () => closeTo(Bob, informTimeout));
        commit();
        
        unknowable(Bob, Alice(_handAlice, _saltAlice)); // Makes sure _handAlice and _saltAlice are not visible to Bob at this point in the code

        Bob.only(() => {
            const handBob = declassify(interact.getHand())
        });

        Bob.publish(handBob)
            .timeout(relativeTime(deadline), () => closeTo(Alice, informTimeout))
        commit();

        Alice.only(() => {
            const saltAlice = declassify(_saltAlice)
            const handAlice = declassify(_handAlice)
        });

        Alice.publish(saltAlice, handAlice)
            .timeout(relativeTime(deadline), () => closeTo(Bob, informTimeout));
        
        checkCommitment(commitAlice, saltAlice, handAlice);

        outcome = winner(handAlice, handBob);
        continue
    }

    assert(outcome == A_WINS || outcome == B_WINS);
    transfer(2 * wager).to(outcome == A_WINS ? Alice : Bob);
    commit();

    each([Alice, Bob], () => {
        interact.setOutcome(outcome);
    });
});