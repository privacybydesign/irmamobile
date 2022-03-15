import Foundation

@objc enum AESKeyError:Int, Error {
    case keyNotGenerated
}

@objc public class AESKey: NSObject {
    let path = FileManager.default.urls(for: .libraryDirectory,
                                           in: .userDomainMask)[0].appendingPathComponent("storageKey")
    
    @objc func getKey() throws -> Data {
        let aes: AES = try AES.init()
        var encrypted: Data
        
        if FileManager.default.fileExists(atPath: path.path) {
            encrypted = try Data(contentsOf: path)
        } else {
            return try generateAESkey(aes)
        }
        
        return try aes.decrypt(encrypted)
    }

    func generateAESkey(_ aes: AES) throws -> Data {
        var key = Data(count: 32)
        let result = key.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, 32, $0.baseAddress!)
        }
        
        if result == errSecSuccess {
            let encrypted = try aes.encrypt(key)
            try encrypted.write(to: path, options: .completeFileProtection)
            
            return key
        } else {
            throw AESKeyError.keyNotGenerated
        }
    }
}
