import Foundation

@objc enum AESKeyError:Int, Error {
    case keyNotGenerated
}

@objc public class AESKey: NSObject {
    var s: Storage
    let path = FileManager.default.urls(for: .libraryDirectory,
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
            return try generateAESkey()
        }
        
        return try s.decrypt(encrypted!)
    }

    func generateAESkey() throws -> Data {
        var key = Data(count: 32)
        let result = key.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, 32, $0.baseAddress!)
        }
        
        if result == errSecSuccess {
            let encrypted = try s.encrypt(key)
            try encrypted.write(to: path, options: .completeFileProtection)
            
            return key
        } else {
            throw AESKeyError.keyNotGenerated
        }
    }
}
