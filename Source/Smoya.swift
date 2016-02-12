//
//  Smoya.swift
//  Smoya
//
//  Created by Matthijn Dijkstra on 08/02/16.
//

import Foundation

/// Protocol for facilitating parameter generation based on structures of nested structs.
public protocol ReflectiveParameters { }

/// Structs within the target type should implement this protocol so that nested dictionaries can be generated.
public protocol NestedDictionary { }

/// The magic that converts structs to nice dictionaries for parameter use
public extension TargetType where Self: ReflectiveParameters
{
    /// Returns the parameters for this struct through reflection
    var parameters: [String: AnyObject]? {
        var dict = [String : AnyObject]()
        
        self.buildDict(&dict, item: self)
        
        return dict
    }

    /// Build the dictionary for the given object
    private func buildDict(inout dict: [String : AnyObject], item: Any) -> [String : AnyObject]
    {
        // Ignoring the known keys and the path keys for the parameters
        let ignoredKeys = self.knownKeys + self.pathKeys

        let mirror = Mirror(reflecting: item)
        
        for child in mirror.children
        {
            guard let key = child.label else { continue }
            
            if !ignoredKeys.contains(key)
            {
                let value = child.value
                
                // The child is a struct, make it a sub directory
                if value is NestedDictionary
                {
                    var subDict = [String: AnyObject]()
                    dict[key] = buildDict(&subDict, item: value)
                }
                // Just add the value
                else
                {
                    if let value = child.value as? AnyObject
                    {
                        dict[key] = value
                    }
                }
            }
            
        }
        
        return dict
    }

}

/// Adding path parsing to the target type. E.g path: /user/{id} will be 1 if the property id on the struct exists and is 1
public extension TargetType
{
    // Ignoring these default keys for parameters or path
    var knownKeys: [String] { return ["path", "method", "parameters", "sampleData"] }
    
    // Replaces the parsable parts of the path with the correct values and returns the result
    var parsedPath: String {
 
        var path = self.path
        
        let mirror = Mirror(reflecting: self)
        
        for child in mirror.children
        {
            guard let key = child.label else { continue }
            
            if !self.knownKeys.contains(key)
            {
                let stringToReplace = "{\(key)}";
                var replacingString = stringToReplace
                
                if let value = child.value as? CustomStringConvertible
                {
                    replacingString = value.description
                }
                else if let value = child.value as? String
                {
                    replacingString = value
                }
                else
                {
                    replacingString = "\(child.value)"
                }
                
                path = path.stringByReplacingOccurrencesOfString(stringToReplace, withString: replacingString)
            }
        }
        
        return path
    }
    
    /// Determines the keys used in the path (For now only matching {this} not advanced paths like {?this})
    var pathKeys: [String] {
        
        var pathKeys = [String]()
        
        do
        {
            let regex = try NSRegularExpression(pattern: "{[a-zA-Z]*}", options: .CaseInsensitive)
            let matches = regex.matchesInString(self.path, options: [], range: NSMakeRange(0, self.path.characters.count))
            
            for match in matches
            {
                if let rangeOfString = self.rangeFromNSRange(match.rangeAtIndex(1), forString: self.path)
                {
                    let string = self.path.substringWithRange(rangeOfString)
                    if !pathKeys.contains(string)
                    {
                        pathKeys.append(string)
                    }
                }
            }
        }
        catch {
            // Not gonna happen
        }
        
        return pathKeys
    }
    
    // Thanks https://www.hackingwithswift.com/example-code/strings/nsregularexpression-how-to-match-regular-expressions-in-strings
    private func rangeFromNSRange(nsRange: NSRange, forString str: String) -> Range<String.Index>? {
        let fromUTF16 = str.utf16.startIndex.advancedBy(nsRange.location, limit: str.utf16.endIndex)
        let toUTF16 = fromUTF16.advancedBy(nsRange.length, limit: str.utf16.endIndex)
        
        
        if let from = String.Index(fromUTF16, within: str),
            let to = String.Index(toUTF16, within: str) {
                return from ..< to
        }
        
        return nil
    }
}