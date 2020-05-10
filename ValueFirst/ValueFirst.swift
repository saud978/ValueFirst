//
//  ValueFirst.swift
//  ValueFirst
//
//  Created by Saud Almutlaq on 10/05/2020.
//  Copyright © 2020 Saud Soft. All rights reserved.
//

import Foundation
import SWXMLHash
import PhoneNumberKit

public class ValueFirst {
    var username:String = ""
    var password:String = ""
    var senderName:String = ""
    
    let phoneNumberKit = PhoneNumberKit()
    
    /// Init the object with needed values to use to send messages and get credit
    /// - Parameters:
    ///   - username: username povided by ValueFirst upon your subscription
    ///   - password: passowrd for you ValueFirst account
    ///   - senderName: the sender name registerd and aproved by ValueFirst
    public init(username:String, password:String, senderName:String) {
        self.username = username
        self.password = password
        self.senderName = senderName
    }
    
    /// Get the subscription credit and used messages
    ///
    /// - Parameter completionBlock: Return a custom struct containing credit, used and balance of messages
    /// - Returns: CreditStruct
    public func getCredits(completionBlock: @escaping (CreditStruct) -> Void) -> Void {
        
        let requestBody = """
        <?xml version="1.0" encoding="ISO-8859-1"?>
        <!DOCTYPE REQUESTCREDIT SYSTEM "http://127.0.0.1/smpp/dtd/requestcredit.dtd">
        <REQUESTCREDIT USERNAME="\(username)" PASSWORD="\(password)">
        </REQUESTCREDIT>
        """
        
        /* return
         <SMS-Credit User="username">
         <Credit Limit="40016" Used="85.0000"/>
         </SMS-Credit>
         */
        
        //create the url with URL
        let url = URL(string: "http://meapi.myvaluefirst.com/smpp/servlet/psms.Eservice2")!
        
        var reqBody = URLComponents()
        reqBody.queryItems = [URLQueryItem(name: "data", value: requestBody),
                              URLQueryItem(name: "action", value: "credits")]
        
        //now create the URLRequest object using the url object
        var request = URLRequest(url: url)
        
        request.httpMethod = "POST"
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = reqBody.query?.data(using: .utf8)
        
        //create dataTask using the session object to send data to the server
        //        fetchCredit(withSession: session, andRequest: request, completionBlock: (String) -> Void)
        fetchData(withRequest: request) { (data) in
            let xml = SWXMLHash.parse(data)
            
            let limit = Int(xml["SMS-Credit"]["Credit"][0].element?.attribute(by: "Limit")?.text ?? "0") ?? 0
            let used = Int(Double(xml["SMS-Credit"]["Credit"][0].element?.attribute(by: "Used")?.text ?? "0") ?? 0)
            let balance = limit - used
            
            let output: CreditStruct = CreditStruct(limit: limit, used: used, balance: balance)
            //send this block to required place
            completionBlock(output)
        }
    }
    
    /// Use this function to send a message to specific number
    /// - Parameters:
    ///   - recevierNumber: (String) reciver number in international format
    ///   - message: (String) the massege to send
    ///   - completionBlock: Handle the code completion
    /// - Returns: (String) "Sent." if the code success send the message
    public func sendMessage(toNumber recevierNumber: String, messageText message:String, completionBlock: @escaping (String) -> Void) -> Void {
        
        let rcNum = recevierNumber
        var formatedRcNum = ""
        
        do {
            let phoneNumber = try phoneNumberKit.parse(rcNum)
            formatedRcNum = phoneNumberKit.format(phoneNumber, toType: .e164) // +61236618300
        }
        catch {
            print("Generic parser error")
        }
        
        let encMsg = message.addingPercentEncoding(withAllowedCharacters: CharacterSet.alphanumerics
            .union(CharacterSet.urlPathAllowed)
            .union(CharacterSet.urlHostAllowed))!
        
        let urlString = "http://meapi.myvaluefirst.com/smpp/sendsms?username=\(username)&password=\(password)&to=\(formatedRcNum)&from=\(senderName)&coding=3&text=\(encMsg)"
        
//        print(urlString)
        let url = URL(string: urlString)!
        
        // Create URL Request
        var request = URLRequest(url: url)
        
        // Specify HTTP Method to use
        request.httpMethod = "GET"
        
        fetchData(withRequest: request) { (data) in
            if let dataString = String(data: data, encoding: .utf8) {
                print("Response data string:\n \(dataString)")
                DispatchQueue.main.async {
                    completionBlock("Sent")
                }
            }
        }
    }
    
    /// Fetching Data Used to send messages and get credit
    /// - Parameters:
    ///   - request: URLRequest to send the message or get the credit
    ///   - completionBlock: Handle the completion of the code
    /// - Returns: Data
    private func fetchData(withRequest request: URLRequest, completionBlock: @escaping (Data) -> Void) -> Void {
        let session = URLSession.shared

        _ = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
            
            guard error == nil else {
                return
            }
            
            guard let data = data else {
                return
            }
            
            completionBlock(data)
        }).resume()
    }
}


/// To hold the credit info
public struct CreditStruct {
    public var limit:Int
    public var used:Int
    public var balance:Int
}
