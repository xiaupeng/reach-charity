'reach 0.1';


const [ isResult, NO_WINS, A_WINS, B_WINS, DRAW,  ] = makeEnum(4);

const winner = (handAgnes, guessAgnes, handBenny, guessBenny) => {
  const total = handAgnes + handBenny;

  if ( guessAgnes == total && guessBenny == total  ) {
      return DRAW
  }  else if ( guessBenny == total) {
      return B_WINS
  }
  else if ( guessAgnes == total ) { 
      return A_WINS
  } else {
      return NO_WINS
  }
 
}
  
assert(winner(1,2,1,3 ) == A_WINS);
assert(winner(5,10,5,8 ) == A_WINS);

assert(winner(3,6,4,7 ) == B_WINS);
assert(winner(1,5,3,4 ) == B_WINS);

assert(winner(0,0,0,0 ) == DRAW);
assert(winner(2,4,2,4 ) == DRAW);
assert(winner(5,10,5,10 ) == DRAW);

assert(winner(3,6,2,4 ) == NO_WINS);
assert(winner(0,3,1,5 ) == NO_WINS);

forall(UInt, handAgnes =>
  forall(UInt, handBenny =>
    forall(UInt, guessAgnes =>
      forall(UInt, guessBenny =>
    assert(isResult(winner(handAgnes, guessAgnes, handBenny , guessBenny)))
))));


// Here to Setup common functions
const commonInteract = {
  ...hasRandom,
  reportResult: Fun([UInt], Null),
  reportHands: Fun([UInt, UInt, UInt, UInt], Null),
  informTimeout: Fun([], Null),
  getHand: Fun([], UInt),
  getGuess: Fun([], UInt),
};

const agnesInterect = {
  ...commonInteract,
  wager: UInt, 
  deadline: UInt, 
}

const bennyInteract = {
  ...commonInteract,
  acceptWager: Fun([UInt], Null),
}


export const main = Reach.App(() => {
  const Agnes = Participant('Agnes',agnesInterect );
  const Benny = Participant('Benny', bennyInteract );
  init();

  // Check for timeouts
  const informTimeout = () => {
    each([Agnes, Benny], () => {
      interact.informTimeout();
    });
  };

  Agnes.only(() => {
    const wager = declassify(interact.wager);
    const deadline = declassify(interact.deadline);
  });
  Agnes.publish(wager, deadline)
    .pay(wager);
  commit();

  Benny.only(() => {
    interact.acceptWager(wager);
  });
  Benny.pay(wager)
    .timeout(relativeTime(deadline), () => closeTo(Agnes, informTimeout));
  

  var result = DRAW;
   invariant( balance() == 2 * wager && isResult(result) );

   while ( result == DRAW || result == NO_WINS ) {
    commit();

  Agnes.only(() => {
    const _handAgnes = interact.getHand();
    const [_commitAgnes1, _saltAgnes1] = makeCommitment(interact, _handAgnes);
    const commitAgnes1 = declassify(_commitAgnes1);

    const _guessAgnes = interact.getGuess();
    const [_commitAgnes2, _saltAgnes2] = makeCommitment(interact, _guessAgnes);
    const commitAgnes2 = declassify(_commitAgnes2);

  })
  

  Agnes.publish(commitAgnes1, commitAgnes2)
      .timeout(relativeTime(deadline), () => closeTo(Benny, informTimeout));
    commit();


    unknowable(Benny, Agnes(_handAgnes,_guessAgnes, _saltAgnes1,_saltAgnes2 ));
  
  Benny.only(() => {
    const handBenny = declassify(interact.getHand());
    const guessBenny = declassify(interact.getGuess());
  });

  Benny.publish(handBenny, guessBenny)
    .timeout(relativeTime(deadline), () => closeTo(Agnes, informTimeout));
  commit();

  Agnes.only(() => {
    const saltAgnes1 = declassify(_saltAgnes1);
    const handAgnes = declassify(_handAgnes);
    const saltAgnes2 = declassify(_saltAgnes2);
    const guessAgnes = declassify(_guessAgnes);

  });

  Agnes.publish(saltAgnes1,saltAgnes2, handAgnes, guessAgnes)
    .timeout(relativeTime(deadline), () => closeTo(Benny, informTimeout));
  checkCommitment(commitAgnes1, saltAgnes1, handAgnes);
  checkCommitment(commitAgnes2, saltAgnes2, guessAgnes);

  // Report results to all participants
  each([Agnes, Benny], () => {
    interact.reportHands(handAgnes, guessAgnes, handBenny, guessBenny);
  });

  result = winner(handAgnes, guessAgnes, handBenny, guessBenny);
  continue;
}


assert(result == A_WINS || result == B_WINS);

each([Agnes, Benny], () => {
  interact.reportResult(result);
});

transfer(2 * wager).to(result == A_WINS ? Agnes : Benny);
commit();

});
