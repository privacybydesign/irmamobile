import Foundation

@objc enum AESKeyError:Int, Error {
    case keyNotGenerated
}

@objc public class AESKey: NSObject {
    let path = FileManager.default.urls(for: .libraryDirectory,
                                           in: .userDomainMask)[0].appendingPathComponent("storageKey")
    
    @objc func getKey() throws -> Data {
        let s: Storage = try Storage.init()
        var encrypted: Data?
        
        if FileManager.default.fileExists(atPath: path.absoluteString) {
            encrypted = try Data(contentsOf: path)
        } else {
            return try generateAESkey(s)
        }
        
        return try s.decrypt(encrypted!)
    }

    func generateAESkey(_ s: Storage) throws -> Data {
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
