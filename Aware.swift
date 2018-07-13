//
//  Aware.swift
//  aware
//
//  Created by Michael DeBiase on 1/30/18.
//  Copyright © 2018 Armoredware. All rights reserved.
//

import UIKit
import Foundation


func getWiFiAddress() -> String? {
    var address : String?
    
    // Get list of all interfaces on the local machine:
    var ifaddr : UnsafeMutablePointer<ifaddrs>?
    guard getifaddrs(&ifaddr) == 0 else { return nil }
    guard let firstAddr = ifaddr else { return nil }
    
    // For each interface ...
    for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
        let interface = ifptr.pointee
        
        // Check for IPv4 or IPv6 interface:
        let addrFamily = interface.ifa_addr.pointee.sa_family
        
        if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
            
            // Check interface name:
            let name = String(cString: interface.ifa_name)
            print("device names:",name);
            if  name == "en0" {
                
                // Convert interface address to a human readable string:
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                            &hostname, socklen_t(hostname.count),
                            nil, socklen_t(0), NI_NUMERICHOST)
                address = String(cString: hostname)
                print("Adress:",address!);
            }
        }
    }
    freeifaddrs(ifaddr)
    
    return address
}




/*
func ccSha256(data: Data) -> Data {
    var digest = Data(count: Int(CC_SHA256_DIGEST_LENGTH))
    
    _ = digest.withUnsafeMutableBytes { (digestBytes) in
        data.withUnsafeBytes { (stringBytes) in
            CC_SHA256(stringBytes, CC_LONG(data.count), digestBytes)
        }
    }
    return digest
}*/

extension String {
    
    func sha256() -> String{
        if let stringData = self.data(using: String.Encoding.utf8) {
            return hexStringFromData(input: digest(input: stringData as NSData))
        }
        return ""
    }
    
    private func digest(input : NSData) -> NSData {
        let digestLength = Int(CC_SHA256_DIGEST_LENGTH)
        var hash = [UInt8](repeating: 0, count: digestLength)
        CC_SHA256(input.bytes, UInt32(input.length), &hash)
        return NSData(bytes: hash, length: digestLength)
    }
    
    private  func hexStringFromData(input: NSData) -> String {
        var bytes = [UInt8](repeating: 0, count: input.length)
        input.getBytes(&bytes, length: input.length)
        
        var hexString = ""
        for byte in bytes {
            hexString += String(format:"%02x", UInt8(byte))
        }
        
        return hexString
    }
    
}



struct Tx{
    var sender: String
    var recipient: String
    var amount: Int
    var lastBlock: Int
    
    init(sender: String, recipient: String, amount: Int, lastBlock: Int){
        self.sender = sender
        self.recipient = recipient
        self.amount = amount
        self.lastBlock = lastBlock
    }
}

struct Block{
    var index: Int
    var timestamp: String
    var txs: [Tx]
    var proof: Int
    var prevHash: String
    init(index: Int, timestamp: String, txs: [Tx], proof: Int, prevHash: String){
        self.index = index
        self.timestamp = timestamp
        self.txs = txs
        self.proof = proof
        self.prevHash = prevHash
    }
}

class BlockChain{
    
    var chain: [Block]
    var currentTx: [Tx]
    
    init(){
        self.chain = []
        self.currentTx = []
        self.addBlock(prevHash: "1", proof: 100)
    }
    
    func addBlock(prevHash: String, proof: Int) -> Block{
        //creates new block and adds it to the chain
        let ts = String(NSDate().timeIntervalSince1970)
        let newBlock = Block(index: self.chain.count + 1, timestamp: ts, txs: self.currentTx, proof: proof, prevHash: prevHash)
        self.chain.append(newBlock)
        
        //set currentTx to zero
        self.currentTx = []
        
        return newBlock
    }
    
    func newTx(sender: String, recipient: String, amount: Int) -> Int{
        
        //adds a new transaction to the list of transactions
        let lstBlock: Int = self.lastBlock()
        let newTx = Tx(
            sender: sender,
            recipient: recipient,
            amount: amount,
            lastBlock: lstBlock )
        self.currentTx.append(newTx)
        return lstBlock + 1
    }
    
    func lastBlock() -> Int{
        //returns last block
        let lastBlockAry: Block! = self.chain.last
        //print (lastBlockAry.index)
        return lastBlockAry.index
    }
    
    func lastBlockasBlock() -> Block{
        //returns last block
        let lastBlockAry: Block! = self.chain.last
        //print (lastBlockAry.index)
        return lastBlockAry
    }
    
    func lastProof() -> Int{
        //returns last block
        let lastBlockAry: Block! = self.chain.last
        //print (lastBlockAry.index)
        return lastBlockAry.proof
    }
    
    
    func hashBlock(clearBlock: Block) -> String{
        //hashes a block
        
        let hashString = "\(clearBlock)"
        let hash = hashString.sha256()
        /*let data = ccSha256(data: str.data(using: .utf8)!)
        let hash = "\(data.map { String(format: "%02hhx", $0) }.joined())"*/
        print(hash)
        return hash
    }
    
    func printChain(){
        print(self.chain)
    }
    
    func proofOfWork(lastProof: Int) -> Int{
        //find proof of work
        var proof: Int = 0
        while self.validateProof(lastProof: lastProof, proof: proof) == false{
        proof += 1
        }
        
        return proof
    }
    
    func validateProof(lastProof: Int, proof: Int) -> Bool{
        //check to see if our proofs are valid
        
        let guess: String = "\(lastProof)\(proof)"
        let guessHash: String = guess.sha256()
        let guessHashTest: String = String(guessHash.suffix(4))
        
        if guessHashTest == "0000"{
            return true
        }
        else{
            return false
        }
    }
    
    func mine(){
        //mine the coins
        // run proof of work to get next proof number
        print("mining")
        let nodeID = "9cbcb347e0734905b0chc7955baemjd1"
        let lastBlock = self.lastBlockasBlock()
        let lastProof = self.lastProof()
        var proof = self.proofOfWork(lastProof: lastProof)
        self.newTx(
            sender: "0",
            recipient: nodeID,
            amount: 1
            )
        
        let prevHash = self.hashBlock(clearBlock: lastBlock)
        let block = self.addBlock(prevHash: prevHash, proof: proof)
        //forging new block
        print("message: New Block Forged")
        print(block)
        
    }
    
    
}




