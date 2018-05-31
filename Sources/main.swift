import PerfectHTTP
import PerfectHTTPServer
import PerfectSQLite
import PerfectLib
import PerfectNotifications
import PerfectCrypto
import Foundation


// Column String For USERS Table
let USERS_TABLE = "USERS"
let LOGIN_ERROR = "LOGIN_ERROR"

// database path
//let dbPath = "/Users/jose/Desktop/Master/TestPerfect/DB/wehave.db"
let dbPath = "/home/jscoder/DB/wehave.db"  // Change Your path


// configuration Push
let notificationsAppId = "com.js.wehave"
let apnsTeamIdentifier = "Q9FQ8LK3ZQ"
let apnsKeyIdentifier = "D36242MKZU"
//let apnsPrivateKeyFilePath = "/Users/jose/Desktop/Master/TestPerfect/AuthKey_D36242MKZU.p8"
let apnsPrivateKeyFilePath = "/home/jscoder/Certification/AuthKey_D36242MKZU.p8"// Change your path
let DEVICE_TOKEN = "device_token"
let NOTIFICATION = "notification"


// Default SMS
let API_TOKEN_SMS = "0bee4c5898709226b7a55690b62bf2f0530d55cf"
let CODE_SMS = 4812

// USERS COLUMN Index
enum USERS: Int {
    case ID = 0
    case USER = 1
    case PASSWORD = 2
    case PHONE_NUMBER = 3
    case EMAIL = 4
    case LOCATION = 5
    case IMAGE = 6
    case USER_TOKEN = 7
}

// USERS COLUMN Name
enum USERS_NAME: String {
    case USER = "USER"
    case PASSWORD = "PASSWORD"
    case PHONE_NUMBER = "PHONE_NUMBER"
    case EMAIL = "EMAIL"
    case LOCATION = "LOCATION"
    case IMAGE = "IMAGE"
    case USER_TOKEN = "USER_TOKEN"
}
// DEVICES COLUMN NAME
enum DEVICES:Int {
    case ID = 0
    case DEVICE_TOKEN = 1
}

//APIs USERS TABLE KEYS
enum USERS_KEY: String {
    case ID = "id"
    case USER_NAME = "userName"
    case PASSWORD = "password"
    case PHONE = "phone"
    case EMAIL = "email"
    case LOCATION = "location"
    case IMAGE = "imageUrl"
    case USER_TOKEN = "token"
}

// Function For Create Objeto User
private func setUserData(userId: String, userName: String, userPassword: String, userPhone: String, userEmail: String,
                         userLocation: String, userImage: String, userToken: String)->[String : Any]{
    let data:[String : Any] = [
        USERS_KEY.ID.rawValue : userId,
        USERS_KEY.USER_NAME.rawValue: userName,
        USERS_KEY.PASSWORD.rawValue: userPassword,
        USERS_KEY.PHONE.rawValue: userPhone,
        USERS_KEY.EMAIL.rawValue: userEmail,
        USERS_KEY.LOCATION.rawValue: userLocation,
        USERS_KEY.IMAGE.rawValue: userImage,
        USERS_KEY.USER_TOKEN.rawValue: userToken]
    return data
}

private func pushNotification(deviceToken: String, content: String){
    let n = NotificationPusher(apnsTopic: notificationsAppId)
    n.pushAPNS(configurationName: notificationsAppId, deviceToken: deviceToken, notificationItems:  [.alertBody(content), .sound("default")], callback: { (nResponse) in
        print(nResponse.status.code)
    })
}


// MARK: - Routes API
/* ---------------------------------------------Routes API---------------------------------------------------------*/
// Objet Routes
var routes = Routes()
// Routes / Handler
routes.add(method: .get, uri: "/") {
    request, response in
    response.setHeader(.contentType, value: "text/html")
    response.appendBody(string: "<html><title>Wehave</title><body>Welcome To Wehave!!!</body></html>")
        .completed()
}


/* ---------------------------------------------Notification Push-------------------------------------------------*/

NotificationPusher.addConfigurationAPNS(
    name: notificationsAppId,
    production: false, // Debug == false
    keyId: apnsKeyIdentifier,
    teamId: apnsTeamIdentifier,
    privateKeyPath: apnsPrivateKeyFilePath
)

// MARK: - APIs Push
// Notification Push
routes.add(method: .post, uri:"/notification") { (request, response) in
    guard let deviceToken = request.param(name:NOTIFICATION) else {
        response.completed(status: HTTPResponseStatus.badRequest)
        return
    }
    let n = NotificationPusher(apnsTopic: notificationsAppId)
    n.pushAPNS(configurationName: notificationsAppId, deviceToken: deviceToken, notificationItems:  [.alertBody("Hola Que tal!"), .sound("default")], callback: { (nResponse) in
        print(nResponse)
        if nResponse.status.code == HTTPResponseStatus.ok.code{
            response.appendBody(string: "Success")
            response.completed(status: HTTPResponseStatus.ok)
        }else{
            response.appendBody(string: "Something as Wrong")
            response.completed(status: HTTPResponseStatus.internalServerError)
        }
    })
}



// MARK: - Push With Content
routes.add(method: .get, uri: "/push") { (request, response) in
   let content = request.queryParams
    var devicesToken:[String] = [String]()
    if content.first?.0 == "content" && content.first?.1.count != 0{
        let text = content.first!.1
        let state = "SELECT * FROM Devices;"
        do {
            let data = try SQLite(dbPath)
            // closse data
            defer{
                data.close()
            }
            try data.forEachRow(statement: state, handleRow: { (sqlite:SQLiteStmt, count) in
                let sq:SQLiteStmt  = sqlite
                devicesToken.append(sqlite.columnText(position: DEVICES.DEVICE_TOKEN.rawValue))
                
            })
            for token in devicesToken{
                pushNotification(deviceToken: token, content: text)
                print(token)
            }
        }catch{
                response.appendBody(string: "Bad DataBase")
            response.completed(status: HTTPResponseStatus.serviceUnavailable)
        }
    }else{
        response.completed(status: HTTPResponseStatus.badRequest)

    }
    response.completed()
    
}



// API Login
routes.add(method: .get, uri: "/users") { (request, response) in
    var userData: [String: Any]?
    // open data
    do {
        let data = try SQLite(dbPath)
        // closse data
        defer{
            data.close()
        }
        // code
        let statemente = "SELECT * FROM USERS"
        try data.forEachRow(statement: statemente, handleRow: { (sqlSmt: SQLiteStmt, index: Int) in
            userData = setUserData(userId: sqlSmt.columnText(position: USERS.ID.rawValue),
                                   userName: sqlSmt.columnText(position: USERS.USER.rawValue),
                                   userPassword: sqlSmt.columnText(position: USERS.PASSWORD.rawValue),
                                   userPhone: sqlSmt.columnText(position: USERS.PHONE_NUMBER.rawValue),
                                   userEmail: sqlSmt.columnText(position: USERS.EMAIL.rawValue),
                                   userLocation: sqlSmt.columnText(position: USERS.LOCATION.rawValue),
                                   userImage: sqlSmt.columnText(position: USERS.IMAGE.rawValue),
                                   userToken: sqlSmt.columnText(position: USERS.USER_TOKEN.rawValue))
        })
        if userData != nil{
        let json = try userData.jsonEncodedString()
            response.appendBody(string:json)
            response.completed(status: HTTPResponseStatus.ok)
            
        }else {
            response.appendBody(string:"No Hay Usuarios")
            response.completed(status: HTTPResponseStatus.ok)
        }
        //error
    }catch{
        print("error")
        response.appendBody(string: "Faild")
        response.completed(status: HTTPResponseStatus.serviceUnavailable)
    }
}

// MARK: - APIs Register
routes.add(method: .post, uri: "/register") { (request, response) in
    guard let userName = request.param(name: USERS_KEY.USER_NAME.rawValue),
        let password = request.param(name: USERS_KEY.PASSWORD.rawValue),
        let phone = request.param(name: USERS_KEY.PHONE.rawValue),
        let email = request.param(name:USERS_KEY.EMAIL.rawValue)else {
            response.appendBody(string: "-1")
            response.completed(status: HTTPResponseStatus.badRequest)
            return
    }
    // Crypto Encode Sha256 / MD5
    let strEncode = userName + phone + email
    guard let enc = strEncode.digest(.md5)?.encode(.hex),
        let userToken = String(validatingUTF8:enc) else{
            response.appendBody(string: "-1")
            response.completed(status: HTTPResponseStatus.serviceUnavailable)
            return}
    // gestion DataBase
    do {
        let data = try SQLite(dbPath)
        
        
        let statemente = "INSERT INTO USERS (\(USERS_NAME.USER), \(USERS_NAME.PASSWORD),\(USERS_NAME.PHONE_NUMBER),\(USERS_NAME.EMAIL),\(USERS_NAME.LOCATION), \(USERS_NAME.USER_TOKEN)) VALUES (\'\(userName)\', \'\(password)\', \'\(phone)\', \'\(email)\', \'Madrid\', \'\(userToken)\');"
      
        print(statemente)
        try data.execute(statement: statemente)
        let body: [String: Any] = ["status": true, "user_Token": userToken]
        let json = try? body.jsonEncodedString()
        response.appendBody(string:json ?? "\(userToken)")
        response.completed()
        defer{
            data.close()
        }
    }catch{
        response.appendBody(string: "Error Database")
        response.completed(status: HTTPResponseStatus.serviceUnavailable)
    }
}


// MARK: - APIs Login
// API Login
routes.add(method: .post, uri: "/login") { (request, response) in
    var userData: [String: Any]?
    guard let userName = request.param(name: USERS_KEY.USER_NAME.rawValue) else {
        response.appendBody(string: LOGIN_ERROR + ". ")
        response.completed(status: HTTPResponseStatus.badRequest)
        return
    }
    guard let password = request.param(name: USERS_KEY.PASSWORD.rawValue) else {
        response.appendBody(string: LOGIN_ERROR + ". ")
        response.completed(status: HTTPResponseStatus.badRequest)
        return
    }
    
    if !(userName.count > 0 && password.count > 0){
        response.appendBody(string:"Failed")
        response.completed(status: HTTPResponseStatus.badRequest)
    }else{
        // open data
        do {
            let data = try SQLite(dbPath)
            // closse data
            defer{
                data.close()
            }
            // code
            let statemente = "SELECT * FROM \(USERS_TABLE) WHERE \(USERS.PHONE_NUMBER) = \(userName) AND \(USERS.PASSWORD) = " + "'" + password + "'"
            print(statemente)
            try data.forEachRow(statement: statemente, handleRow: { (sqlSmt: SQLiteStmt, index: Int) in
                if index == 0{
                    response.appendBody(string: "Account o Password Not Allow")
                    response.completed(status: HTTPResponseStatus.badRequest)
                }
                userData = [String: Any]()
                userData = setUserData(userId: sqlSmt.columnText(position: USERS.ID.rawValue),
                                       userName: sqlSmt.columnText(position: USERS.USER.rawValue),
                                       userPassword: sqlSmt.columnText(position: USERS.PASSWORD.rawValue),
                                       userPhone: sqlSmt.columnText(position: USERS.PHONE_NUMBER.rawValue),
                                       userEmail: sqlSmt.columnText(position: USERS.EMAIL.rawValue),
                                       userLocation: sqlSmt.columnText(position: USERS.LOCATION.rawValue),
                                       userImage: sqlSmt.columnText(position: USERS.IMAGE.rawValue),
                                       userToken: sqlSmt.columnText(position: USERS.USER_TOKEN.rawValue))
            })
            guard let ud = userData else {
                response.appendBody(string: "Account o Password Not Allow")
                response.completed(status: HTTPResponseStatus.badRequest)
                return }
            let json = try ud.jsonEncodedString()
            response.appendBody(string:json)
            response.completed(status: HTTPResponseStatus.ok)
            //error
        }catch{
            print("error")
            response.appendBody(string: "Faild")
            response.completed(status: HTTPResponseStatus.serviceUnavailable)
        }}
}

// MARK: - APIs Device_Token
// Device Token API
routes.add(method: .post, uri: "/device") { (request, response) in
    guard let deviceToken = request.param(name:DEVICE_TOKEN) else {
        response.appendBody(string: "Error Device Token")
        response.completed(status: HTTPResponseStatus.badRequest)
        return
    }
    do {
        // Close Data
        let data = try SQLite(dbPath)
        defer{
            data.close()
        }
        let statemente = "INSERT INTO DEVICES (DEVICE_TOKEN) VALUES ('\(deviceToken)')"
        print(statemente)
        try data.execute(statement: statemente)
        response.appendBody(string: "Success")
        response.completed()
    }catch{
        print("error gestion data")
        response.appendBody(string: "Exist")
        response.completed(status: HTTPResponseStatus.notModified)
    }
}


// MARK: - APIs Send SMS
// API SENDER SMS
routes.add(method: .post, uri: "/sms") { (request, response) in
    var userData: [String: Any]?
    guard let phone = request.param(name: USERS_KEY.PHONE.rawValue)else {response.appendBody(string: "Faild")
        response.completed(status: HTTPResponseStatus.badRequest)
        return
    }
    //Verificar phone
    do {
        // Close Data
        let data = try SQLite(dbPath)
        defer{
            data.close()
        }
        let statemente = "SELECT * FROM USERS WHERE PHONE_NUMBER = \(phone)"
        print(statemente)
        
        // 事务 transaction begin commi rollback
//        try data.doWithTransaction(closure: {
//
//        })
        
        try data.forEachRow(statement: statemente, handleRow: { (sqlSmt: SQLiteStmt, index: Int) in
            userData = setUserData(userId: sqlSmt.columnText(position: USERS.ID.rawValue),
                                   userName: sqlSmt.columnText(position: USERS.USER.rawValue),
                                   userPassword: sqlSmt.columnText(position: USERS.PASSWORD.rawValue),
                                   userPhone: sqlSmt.columnText(position: USERS.PHONE_NUMBER.rawValue),
                                   userEmail: sqlSmt.columnText(position: USERS.EMAIL.rawValue),
                                   userLocation: sqlSmt.columnText(position: USERS.LOCATION.rawValue),
                                   userImage: sqlSmt.columnText(position: USERS.IMAGE.rawValue),
                                   userToken: sqlSmt.columnText(position: USERS.USER_TOKEN.rawValue))
        })
        if userData != nil{
            response.appendBody(string:"-1")
            response.completed(status:HTTPResponseStatus.badRequest)
        }else{
            var postData: Data?
            let headers = [
                "authorization": API_TOKEN_SMS,
                "content-type": "application/json"
            ]
            let paramaters = [ "from": "Wehave",
                               "to": "+34\(phone)",
                "text": "Your activation code is \(CODE_SMS)"]
            
            if #available(OSX 10.13, *) {
                postData = try? JSONSerialization.data(withJSONObject: paramaters, options: JSONSerialization.WritingOptions.sortedKeys)
            } else {
                postData = try? JSONSerialization.data(withJSONObject: paramaters, options:JSONSerialization.WritingOptions.prettyPrinted )
                // Fallback on earlier versions
            }
            var req = URLRequest(url: URL.init(string: "https://api.instasent.com/sms/")!, cachePolicy: URLRequest.CachePolicy.useProtocolCachePolicy, timeoutInterval: 10.0)
            req.httpMethod = "POST"
            req.allHTTPHeaderFields = headers
            req.httpBody = postData!
            let session = URLSession.shared
            let dataTask = session.dataTask(with: req, completionHandler: { (data, sResponse, error) in
                if (error != nil) {
                    response.appendBody(string:"-1")
                    response.completed(status:HTTPResponseStatus.serviceUnavailable)
                } else {
                    //                    let httpResponse = sResponse as? HTTPURLResponse
                    let body: [String : Any] = ["code" : CODE_SMS,
                                                "status" : true]
                    let json = try? body.jsonEncodedString()
                    response.appendBody(string:json ?? "\(CODE_SMS)")
                    response.completed(status:HTTPResponseStatus.ok)
                }
            })
            dataTask.resume()
        }
        //error
    }catch{
        print("error")
        response.completed(status: HTTPResponseStatus.serviceUnavailable)
    }}


// MARK: - Server Life
/* ---------------------------------------------Run Server---------------------------------------------------------*/
do {
    // 启动HTTP服务器
    try HTTPServer.launch(
        .server(name: "localhost", port: 8181, routes: routes))
} catch {
    fatalError("\(error)") // fatal error launching one of the servers
}
extension String{
}
