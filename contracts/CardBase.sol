pragma solidity ^0.4.17;

/**
    cliff maid shift sleep original miracle salt miss path load echo guitar
*/

contract CardBase {
    Card[] public cards;
    Game[] public games;

    uint dnaModulus = 10 ** 16;

    event GameCreated(address indexed _from, uint256 _gameId, Game _game);

    function countCards() public view returns (uint) {
        return cards.length;
    }

    /// @dev A mapping from card IDs to the address that owns them. All cards have
    ///  some valid owner address, even gen0 cats are created with a non-zero owner.
    mapping (uint256 => address) public cardIndexToOwner;
    mapping (uint256 => Game) public gameIdToGame;
    // @dev A mapping from owner address to count of tokens that address owns.
    //  Used internally inside balanceOf() to resolve ownership count.
    mapping (address => uint256) ownershipTokenCount;

    struct Game {
        address playerA;
        address playerB;
        address lastPlayer;
        address winner;
        uint currentRound;
        uint round1PlayerAPoints;
        uint round2PlayerAPoints;
        uint round3PlayerAPoints;
        uint round1PlayerBPoints;
        uint round2PlayerBPoints;
        uint round3PlayerBPoints;
    }

    function startGame() public {
        Game memory game = Game(msg.sender, 0x0, msg.sender, 0x0, 0, 0, 0, 0, 0, 0, 0);

        uint gameId = games.push(game) - 1;

        gameIdToGame[gameId] = game;

        emit GameCreated(msg.sender, gameId, game);
    }

    modifier isMyCard(uint cardId) {
        require(
            cardIndexToOwner[cardId] == msg.sender,
            "This card does not belong to you."
        );
        _;
    }

    modifier nextTurnIsMine(uint gameId) {
        require(
            games[gameId].lastPlayer != msg.sender,
            "This is not your turn."
        );
        _;
    }

    function _nextRound(Game storage game) internal {
        game.currentRound = game.currentRound + 1;
    }

    modifier partOfTheGame(uint gameId) {
        Game storage game = games[gameId];

        uint notTwo = 0;

        if (game.playerA != msg.sender) {
            notTwo++;
        }

        if (game.playerB != msg.sender) {
            notTwo++;
        }

        require(
            notTwo != 2,
            "You are not part of the game!"
        );
        _;
    }

    function nextRound(uint gameId) public nextTurnIsMine(gameId) partOfTheGame(gameId) {
        Game storage game = games[gameId];

        _nextRound(game);
    }

    function useCardInGameOrJoinGame(uint gameId, uint cardId)
    public
    isMyCard(cardId)
    nextTurnIsMine(gameId) {
        Game storage game = games[gameId];
        Card storage card = cards[cardId];

        game.playerB = msg.sender;
        game.lastPlayer = msg.sender;

        if (game.playerB == msg.sender) {
            if (game.currentRound == 0) {
                game.round1PlayerAPoints = game.round1PlayerBPoints + card.power;
            }

            if (game.currentRound == 1) {
                game.round1PlayerAPoints = game.round2PlayerBPoints + card.power;
            }

            if (game.currentRound == 2) {
                game.round1PlayerAPoints = game.round2PlayerBPoints + card.power;
            }
        }

        if (game.playerA == msg.sender) {
            if (game.currentRound == 0) {
                game.round1PlayerAPoints = game.round1PlayerAPoints + card.power;
            }

            if (game.currentRound == 1) {
                game.round1PlayerAPoints = game.round2PlayerAPoints + card.power;
            }

            if (game.currentRound == 2) {
                game.round1PlayerAPoints = game.round2PlayerAPoints + card.power;
            }
        }
    }

    struct Card {
        // The ID of the parents of this card, set to 0 for gen0 cats.
        // Note that using 32-bit unsigned integers limits us to a "mere"
        // 4 billion cats. This number might seem small until you realize
        // that Ethereum currently has a limit of about 500 million
        // transactions per year! So, this definitely won't be a problem
        // for several years (even as Ethereum learns to scale).

        // the power
        uint32 power;
        string name;
        // TT - Trump / micky maus ( type of card)
        // P - 0 - 9
        // M - 0-99
        // TTPMM
        uint dna;

        // The "generation number" of this cat. Cats minted by the CK contract
        // for sale are called "gen0" and have a generation number of 0. The
        // generation number of all other cats is the larger of the two generation
        // numbers of their parents, plus one.
        // (i.e. max(matron.generation, sire.generation) + 1)
        uint16 generation;
    }

    modifier isBetterPower(uint cardId, uint power) {
        require (cards[cardId].power >= power);
        _;
    }

    function changeCardName(uint cardId, string name) external isMyCard(cardId) isBetterPower(cardId, 2) {
        Card storage card = cards[cardId];

        card.name = name;
    }

    /// @dev Assigns ownership of a specific Kitty to an address.
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        // Since the number of kittens is capped to 2^32 we can't overflow this
        ownershipTokenCount[_to]++;
        
        // transfer ownership
        cardIndexToOwner[_tokenId] = _to;

        // When creating new kittens _from is 0x0, but we can't account that address.
        // @todo: understand this shit
        if (_from != address(0)) {
            ownershipTokenCount[_from]--;
        }

        // Emit the transfer event.
        // Transfer(_from, _to, _tokenId);
    }

    // everyone can get 10 cards for free
    function createNewCard() public {
        // require(ownershipTokenCount[msg.sender] < 10, "You already have 10 cards");

        _createCard(1, "NoName", 1, msg.sender);
    }

    function _mutate(uint _cardId, uint positiveNegativePoints) internal {
        // «todo cooldown
        require(positiveNegativePoints < 100);

        Card storage card = cards[_cardId];

        card.dna = card.dna - card.dna % 100 + positiveNegativePoints;
    }

    function getSomeRandomDna() public view returns (uint) {
        
        uint random_number = uint(blockhash(block.number-1)) % dnaModulus + 1;

        return random_number;
    }

    function getLastCard() public view returns (uint) {
        return cards[cards.length - 1].dna;
    }

    /// @dev An internal method that creates a new kitty and stores it. This
    ///  method doesn't do any checking and should only be called when the
    ///  input data is known to be valid. Will generate both a Birth event
    ///  and a Transfer event.
    function _createCard(
        uint16 _generation,
        string _name,
        uint32 _power,
        address _owner
    )
        internal
        returns (uint)
    {
        uint dna = getSomeRandomDna();
        Card memory _card = Card(_power, _name, dna, _generation);

        uint256 newCardId = cards.push(_card) - 1;

        // It's probably never going to happen, 4 billion cats is A LOT, but
        // let's just be 100% sure we never let this happen.
        require (newCardId == uint256(uint32(newCardId)));

        // This will assign ownership, and also emit the Transfer event as
        // per ERC721 draft
        _transfer(0, _owner, newCardId);

        return newCardId;
    }
}
