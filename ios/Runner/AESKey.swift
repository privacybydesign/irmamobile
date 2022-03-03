import Foundation

@objc enum AESKeyError:Int, Error {
    case keyNotGenerated
}

@objc public class AESKey: NSObject {
    var s: Storage
    let path = FileManager.default.urls(for: .documentDirectory,
                                           in: .userDomainMask)[0].appendingPathComponent("storageKey")
    
    override init() {
        self.s = try! Storage.init()
        super.init()
    }
        
    @objc func getKey() throws -> Data {

        s = try Storage.init()
        
        var encrypted: Data?
        
        do {
            encrypted = try Data(contentsOf: path)
        } catch {
            encrypted = try generateAESkey()
        }
        
        return try s.decrypt(encrypted!)
    }

    func generateAESkey() throws -> Data {
        var keyData = Data(count: 32)
        let result = keyData.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, 32, $0.baseAddress!)
        }
        
        if result == errSecSuccess {
            let encrypted = try s.encrypt(keyData)
            try encrypted.write(to: path)
            
            return encrypted
        } else {
            throw AESKeyError.keyNotGenerated
        }
    }
}
