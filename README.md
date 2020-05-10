# ValueFirst
Swift 5 library to send messages and get credit for ValueFirst SMS

This is a public iOS library

to use
Add library to your project

## How to use

```Swift
// Create a ValueFirst object with parameters
let obj:ValueFirst = ValueFirst(username: "username", password: "password", senderName: "SENDERNAME")

// to get credit
valueFirst.getCredits(completionBlock: { (output) in
            print("Credit: \(output.limit) /n Used: \(output.used) \n Balance: \(output.balance)")
        })

// to send message
valueFirst.sendMessage(toNumber: "0013123123123", messageText: "Message here") { (result) in
    if result == "Sent" {
        print("Message sent successfully")
    } else {
        print("Error sending message")
    }
}
```
