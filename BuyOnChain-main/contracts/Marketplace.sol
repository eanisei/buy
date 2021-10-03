// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "contracts/NFT.sol";
import "contracts/Stakable.sol";

contract Marketplace is NFT, Stakable{
   
   address payable public Owner;
   enum status{Available, Sold}
   status currentStatus;
   string xyz;
  
   enum orderStatus{OrderPlaced, OrderCancelled, OrderConfirmed, Dispatched, Disputed}
   orderStatus OrderStatus;
   uint public receiptId;
   uint public productId;
   address payable burn =payable(0x000000000000000000000000000000000000dEaD);
   
   constructor() {
       Owner= payable(msg.sender);
       Receipts.push(receipt(0,0,0,burn,burn));
       Products.push(product(xyz, 0,0, burn));
   }
   
   struct product{
       string name;
       uint price;        // price per item
       uint quantity;
       address payable seller;
     
   }
   //mapping (uint=>product) public Product;
   event newProduct(uint productId, string name, uint price, uint quantity, address seller);
   struct receipt{
       uint productId;
       uint quantity;
       uint totalCost;
       address payable buyer;
       address payable seller;
       
   }
   //mapping(uint=>receipt) public Receipt;
   event newOrder(uint receiptId,uint productId,uint quantity, uint totalCost, address buyer,address seller);
   receipt[] public Receipts;
   product[] public Products;

       
   
   modifier notSellor(uint _productId){
       require (msg.sender != Products[_productId].seller, "You are the seller");
       _;
   }
   
   modifier cost(uint _price, uint _quantity){
       require (msg.value==_price*_quantity,  "Please pay the exact amount");
       _;
   }
   
   modifier onlyBuyer(uint _receiptId){
       require(Receipts[_receiptId].buyer==msg.sender, "You are not the buyer of this product!!");
       _;
   }
   
    modifier onlySeller(uint _receiptId){
       require(Receipts[_receiptId].seller==msg.sender, "You are not the seller of this product!!");
       _;
   }
   modifier onlyOwner() override{
       require (msg.sender == Owner, "You are not the owner");
       _;
   }
    
   
    function listItem(string calldata _name, uint _price, uint _quantity) external onlyStakers {
         productId++;
         Products.push(product(_name, _price, _quantity, payable(msg.sender)));
         if (_quantity>=1){
             currentStatus = status.Available;
             emit newProduct(productId, _name, _price, _quantity, msg.sender);
         }
          
    }  
   
   function buy(uint _productId, uint _quantity) external payable notSellor(_productId) cost(Products[_productId].price, _quantity) onlyStakers{
       require (currentStatus== status.Available);
       Products[_productId].quantity-=_quantity;
       OrderStatus= orderStatus.OrderPlaced;
       uint _totalCost= Products[_productId].price*_quantity;
       receiptId++;
       Receipts.push(receipt(_productId, _quantity, _totalCost, payable(msg.sender),Products[_productId].seller));
       emit newOrder(receiptId, _productId, _quantity, Products[_productId].price*_quantity, msg.sender, Products[_productId].seller);
       
       
   }
   
   function orderAccept(uint _receiptId) external payable onlySeller(_receiptId){
       
           OrderStatus=orderStatus.OrderConfirmed;
       }
    
   function orderReject(uint _receiptId) external payable onlySeller(_receiptId){
       
           OrderStatus=orderStatus.OrderCancelled;
           Receipts[_receiptId].buyer.transfer(Receipts[_receiptId].totalCost);
       }
   
   function itemDelivered(uint _receiptId) public onlyBuyer(_receiptId) {
       Receipts[_receiptId].seller.transfer(Receipts[_receiptId].totalCost);
       bytes memory packedDescription= abi.encodePacked(block.timestamp, _receiptId, block.difficulty, Receipts[_receiptId].productId, Receipts[_receiptId].quantity, Receipts[_receiptId].totalCost, Receipts[_receiptId].buyer, Receipts[_receiptId].seller, Receipts.length);
       mintNFT(msg.sender, packedDescription);
       mintNFT(Receipts[_receiptId].seller, packedDescription);
   }
   
  function dispute(uint _receiptId) external payable {
      require(msg.sender==Receipts[_receiptId].buyer||msg.sender==Receipts[_receiptId].seller);
      OrderStatus=orderStatus.Disputed;
       
  }
   
    function resolve(uint _receiptId, address payable _justice) public payable onlyOwner {
      require (_justice==Receipts[_receiptId].buyer||_justice==Receipts[_receiptId].seller, "This is not a buyer or seller of this product!!");
      require (OrderStatus==orderStatus.Disputed, "This transaction is not disputed!!");      
      _justice.transfer(Receipts[_receiptId].totalCost);
    }
    
    
}