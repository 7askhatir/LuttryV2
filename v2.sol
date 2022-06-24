// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./nftLuttry.sol";
contract Lottery{   
    using SafeMath for uint256;
    address public Token;
    address public addressNft;
    address public owner;
    address[] players;
    address[] tokensForThisMounts;
    uint256 tekitId=0;
    address[]  lastWinners;
    Ticket[]  EmptyArray;
    LOTTERY_STATE public lotteryState=LOTTERY_STATE.CLOSED;
    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }
    event StartLottery(address[]  tokens);
    event PauseLotteryForCalculWinner();
    event SetWinners(uint numberWinners);
    struct Ticket{
        uint[] TicketId;
        address user;
        address token;
    }
    NFT nftContrat;
    Ticket[] tikets;
    mapping (uint => address) public tiketToOwner;
    mapping (address => uint) public ownerTiketsCount;
    mapping (address => uint) public numberOfTicketCanShared;

    constructor(address _adreessToken,address _adreessNft){
          Token=_adreessToken;
          owner=_msgSender();
          addressNft=_adreessNft;
          nftContrat=NFT(addressNft);

      }
    modifier onlyOwner() {
        require(_owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
     function _msgSender() internal view virtual returns (address) {
        return msg.sender;
      }
      function _owner() public view virtual returns (address) {
        return owner;
      }
     //change tokens for this mounth 
    function LotteryMounth(address[] memory _tokensForThisMounts) public {
        tokensForThisMounts=_tokensForThisMounts;
    }
    function checkBalanceToken(address _tokenAddress,address _user) public view returns(uint ){
         return ERC20(_tokenAddress).balanceOf(_user);
    }
    function startLottery(address[] memory _tokens) public onlyOwner {
         tokensForThisMounts=_tokens;
         lotteryState=LOTTERY_STATE.OPEN;
         emit StartLottery(_tokens);
    }
    function checkAddressInLotteryMounth(address _tokenAddress) public view returns (bool){
        bool check=false;
        for(uint i=0;i<tokensForThisMounts.length;i++)
           if(tokensForThisMounts[i]==_tokenAddress)
           check=true;
        return check;
    }
    function checkUseralreadyParticipatingForThisToken(address _user,address _token) public view returns(bool){
         bool check=false;
        for(uint i=0;i<tikets.length;i++){
           if(tikets[i].user==_user && tikets[i].token== _token)
           check=true;
        }
        return check;
    }
    function _approve(address _spender, uint256 _amount) public returns(bool) {
      return ERC20(Token).approve(_spender, _amount);
    }
    function _allowance(address _token) public  returns(uint256){
        return ERC20(_token).allowance(_msgSender(),address(this));
    }
    function sharedByBalance(address _tokenAddress) public {
        uint256 tokenAmount = checkBalanceToken(_tokenAddress,_msgSender());
        uint256 gardInoAmount=checkBalanceToken(Token,_msgSender());
        require(tokenAmount>0,"Your balance not suffisant");
        require(checkAddressInLotteryMounth(_tokenAddress),"this token not in list address for this mounts");
        require(!checkUseralreadyParticipatingForThisToken(_msgSender(),_tokenAddress),"this user is already participating for this token");
        require(gardInoAmount>=(10**18),"Your balance GarIno not suffisant");
        _safeTransferFrom(ERC20(_tokenAddress),_msgSender(),owner,tokenAmount);
        uint256 numberOfTikets=checkBalanceToken(Token,_msgSender()).div(10**18);
        numberOfTicketCanShared[_msgSender()] += numberOfTikets;
    }
        function enterToLuttory(address _tokenAddress,uint _tokenId) public {
         NFT.Nft memory nftCanShared=nftContrat.getNftById(_tokenId);
         require(nftContrat.ownerOf(_tokenId)==msg.sender,"your are not owner of this nft");
         require(nftCanShared.hearts>0,"this nft dosn't have healt for this operation");
         require(lotteryState == LOTTERY_STATE.OPEN ,"Lottery Is Closed");
         uint mulNft=100;
         uint256 numberOfTikets=numberOfTicketCanShared[_msgSender()];
         if(_tokenId!=0){
             if(nftCanShared.level==nftContrat.Bronze() && !nftCanShared.Shield){
                 mulNft=intervalRandom(101,105);
             }
             else if(nftCanShared.level==nftContrat.Bronze() && nftCanShared.Shield){
                 mulNft=intervalRandom(106,110);
             }
             else if(nftCanShared.level==nftContrat.Silver() && !nftCanShared.Shield){
                 mulNft=intervalRandom(111,120);
             }
             else if(nftCanShared.level==nftContrat.Silver() && nftCanShared.Shield){
                 mulNft=intervalRandom(121,125);
             }
             else if(nftCanShared.level==nftContrat.Gold()){
                 mulNft=intervalRandom(150,170);
             }
             else if(nftCanShared.level==nftContrat.Diamond()){
                 mulNft=intervalRandom(190,200);
             }
         }
         

        uint256 tiketsShared=numberOfTikets*mulNft/100;
        uint[] memory tiketsIds=new uint[](tiketsShared);
        for(uint i=0;i<tiketsShared;i++){
            tekitId++;
            tiketsIds[i]=tekitId;
            tiketToOwner[tekitId] = _msgSender();
        }
        Ticket memory T = Ticket(tiketsIds,_msgSender(),_tokenAddress);
        tikets.push(T);
        ownerTiketsCount[_msgSender()]+=tiketsShared;
        if(!checkUseralreadyParticipating(_msgSender()))
        players.push(_msgSender());
        numberOfTicketCanShared[_msgSender()]=0;
    }
    function checkUseralreadyParticipating(address _user) public view returns(bool){
        bool check=false;
        for(uint indexOfPlayers=0;indexOfPlayers<players.length;indexOfPlayers++)
        if(players[indexOfPlayers] ==_user)check=true;
        return check;
    }

    function getNumberOfTiketsForUser(address _user) public view returns(uint){
        return ownerTiketsCount[_user];
    }

    function pauseLotteryForCalculatingWinner() public onlyOwner{
      lotteryState=LOTTERY_STATE.CALCULATING_WINNER;
      emit PauseLotteryForCalculWinner();

    }
    function getUserByTicket(uint _idTiket) public view returns(address){
        return tiketToOwner[_idTiket];
    }
    
    // function getAllTicketByUser(address _user) public view returns(uint[] memory){
    //  uint[] memory allTicket=new uint[](getNumberOfTiketsForUser(_user));
    //  uint index=0;
    //  for(uint indexOfTikets=0;indexOfTikets<tikets.length;indexOfTikets++){
    //     if(tikets[indexOfTikets].user==_user){
          
    //     }
    //  }
    // return allTicket;
    // }
    
    function getLastWinners() public view returns(address[] memory){
         return lastWinners;
    }
    
   //change this random to chainLink random is important
    function redum(uint256 MAX_INT_FROM_BYTE,uint256 NUM_RANDOM_BYTES_REQUESTED) public view returns(uint){
        uint ceiling = (MAX_INT_FROM_BYTE * NUM_RANDOM_BYTES_REQUESTED);
        uint randomNumber = uint(keccak256(abi.encodePacked(block.timestamp)))+ceiling;
        uint spin = (randomNumber % 10009) + 1;
        return spin ;
    }

    function setWinnerTicket(uint8 _nuberWinner) public view returns(uint[] memory) {
      require(tikets.length>_nuberWinner,"The number of participants is small");
      uint[] memory a = new uint[](_nuberWinner);
      for(uint i=0;i<_nuberWinner;i++){
          uint256 hash=112233445566778899**2;
          uint256  rnd=uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp,redum(i,hash))));
          a[i]=rnd % tikets.length;
      }
      return a;
    }

    function setWinnersAddress(uint8 _nuberWinner) public onlyOwner{
        uint[] memory winnersTiket=setWinnerTicket(_nuberWinner);
        address[] memory winnersAddress = new address[](_nuberWinner);
        for(uint indexWinnersTiket=0;indexWinnersTiket<winnersTiket.length;indexWinnersTiket++){
            for(uint indexOfTikets=0;indexOfTikets<tikets.length;indexOfTikets++){
                for(uint indexOfTiketId=0;indexOfTiketId<tikets[indexOfTikets].TicketId.length;indexOfTiketId++){
                  if(winnersTiket[indexWinnersTiket]==tikets[indexOfTikets].TicketId[indexOfTiketId])
                  winnersAddress[indexWinnersTiket]=tikets[indexOfTikets].user;
                }
            }
        }
        require(winnersAddress.length==_nuberWinner,"erreur");
        lastWinners=winnersAddress;
        lotteryState=LOTTERY_STATE.CLOSED;
        resetAllTickets();
        emit SetWinners(_nuberWinner);
    }

    function resetAllTickets()public {
        tikets=EmptyArray;
        for(uint indexOfPlayers=0;indexOfPlayers<players.length;indexOfPlayers++)
        ownerTiketsCount[players[indexOfPlayers]]=0;
        tekitId=0;
    }
    function intervalRandom(uint _from ,uint _to) public view returns(uint256){
        uint256 hash=112233445566778899**2;
        uint256  rnd=uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp,hash)));
        return _from+rnd.mod(_to.sub(_from).add(1));
    }

        function _safeTransferFrom(
        ERC20 token,
        address sender,
        address recipient,
        uint amount
    ) private {
        require(sender != address(0),"address of sender Incorrect ");
        bool sent = token.transferFrom(sender, recipient, amount);
        require(sent, "Token transfer failed");
    }
 
 

}
