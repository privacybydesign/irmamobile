import Foundation

enum AESKeyError: Error {
    case keyNotGenerated(_: Int32)
}

@objc public class AESKey: NSObject {
    let path = FileManager.default.urls(for: .libraryDirectory,
                                           in: .userDomainMask)[0].appendingPathComponent("storageKey")
    let tag = "storageKey"
    
    @objc func getKey() throws -> Data {
        let tee: TEE = TEE.init()
        var ciphertext: Data
        
        if FileManager.default.fileExists(atPath: path.path) {
            ciphertext = try Data(contentsOf: path)
        } else {
            return try generateAESkey(tee)
        }
        
        return try tee.decrypt(tag, ciphertext)
    }
    
    private func generateAESkey(_ tee: TEE) throws -> Data {
        var bytes = [UInt8](repeating: 0, count: 32)
        let result = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        
        guard result == errSecSuccess else {
            throw AESKeyError.keyNotGenerated(result)
        }
        
        let key = Data(bytes)
        let ciphertext = try tee.encrypt(tag, key)
        try ciphertext.write(to: path, options: .completeFileProtection)
        
        return key
    }
}
