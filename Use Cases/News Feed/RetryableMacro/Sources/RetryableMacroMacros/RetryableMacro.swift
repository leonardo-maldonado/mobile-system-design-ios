//
//  RetryableMacro.swift
//  RetryableMacroMacros
//
//  Created by Leonardo Maldonado on 8/9/25.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// A macro that adds retry functionality to async functions.
///
/// ## Usage
/// ```swift
/// @Retryable(maxAttempts: 3, baseDelay: 1.0, maxDelay: 5.0)
/// func fetchData() async throws -> Data {
///     // Your async operation here
/// }
/// ```
public struct RetryableMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        
        // Extract parameters from macro
        let maxAttempts = extractParameter(from: node, name: "maxAttempts", defaultValue: "3")
        let baseDelay = extractParameter(from: node, name: "baseDelay", defaultValue: "0.5")
        let maxDelay = extractParameter(from: node, name: "maxDelay", defaultValue: "5.0")
        let jitter = extractParameter(from: node, name: "jitter", defaultValue: "0.0...0.3")
        
        // Get the function declaration
        guard let functionDecl = declaration.as(FunctionDeclSyntax.self) else {
            return [] // Not a function, ignore
        }
        
        // Only generate for concrete functions with bodies
        guard functionDecl.body != nil else {
            return [] // Skip protocol requirements or declarations without bodies
        }
        
        let functionName = functionDecl.name.text
        let returnType = functionDecl.signature.returnClause?.type.description ?? "Void"
        let parameters = functionDecl.signature.parameterClause.parameters
        
        // Generate unique name for the retry wrapper
        let retryFunctionName = context.makeUniqueName("\(functionName)_retrying")
        
        // Generate the parameter call string with proper argument labels
        let parameterCallString = parameters.map { param in
            let label = param.firstName.text
            let secondName = param.secondName?.text ?? param.firstName.text
            return "\(label): \(secondName)"
        }.joined(separator: ", ")
        
        // Generate the retryable wrapper function with a different name
        let retryableFunction = """
        func \(retryFunctionName)(\(parameters.map { $0.description }.joined(separator: ", "))) async throws -> \(returnType) {
            var attempt = 1
            var delay = \(baseDelay)
            
            while true {
                try Task.checkCancellation()
                do {
                    return try await \(functionName)(\(parameterCallString))
                } catch {
                    guard attempt < \(maxAttempts) else { throw error }
                    let jitterFactor = 1 + Double.random(in: \(jitter))
                    let wait = min(\(maxDelay), delay) * jitterFactor
                    try await Task.sleep(nanoseconds: UInt64(wait * 1_000_000_000))
                    delay *= 2
                    attempt += 1
                }
            }
        }
        """
        
        return [DeclSyntax(stringLiteral: retryableFunction)]
    }
    
    private static func extractParameter(from node: AttributeSyntax, name: String, defaultValue: String) -> String {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else { return defaultValue }
        
        for argument in arguments {
            if argument.label?.text == name {
                return argument.expression.description
            }
        }
        
        return defaultValue
    }
}

/// A macro that adds retry functionality with custom retry logic.
///
/// ## Usage
/// ```swift
/// @RetryableWithCondition(maxAttempts: 3) { error, attempt in
///     return error is NetworkError && attempt < 3
/// }
/// func fetchData() async throws -> Data {
///     // Your async operation here
/// }
/// ```
public struct RetryableWithConditionMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        
        // Extract parameters from macro
        let maxAttempts = extractParameter(from: node, name: "maxAttempts", defaultValue: "3")
        let baseDelay = extractParameter(from: node, name: "baseDelay", defaultValue: "0.5")
        let maxDelay = extractParameter(from: node, name: "maxDelay", defaultValue: "5.0")
        let jitter = extractParameter(from: node, name: "jitter", defaultValue: "0.0...0.3")
        let shouldRetryClosure = extractShouldRetryClosure(from: node)
        
        // Get the function declaration
        guard let functionDecl = declaration.as(FunctionDeclSyntax.self) else {
            return [] // Not a function, ignore
        }
        
        // Only generate for concrete functions with bodies
        guard functionDecl.body != nil else {
            return [] // Skip protocol requirements or declarations without bodies
        }
        
        let functionName = functionDecl.name.text
        let returnType = functionDecl.signature.returnClause?.type.description ?? "Void"
        let parameters = functionDecl.signature.parameterClause.parameters
        
        // Generate unique name for the retry wrapper
        let retryFunctionName = context.makeUniqueName("\(functionName)_retrying")
        
        // Generate the parameter call string with proper argument labels
        let parameterCallString = parameters.map { param in
            let label = param.firstName.text
            let secondName = param.secondName?.text ?? param.firstName.text
            return "\(label): \(secondName)"
        }.joined(separator: ", ")
        
        // Generate the retryable wrapper function with a different name
        let retryableFunction = """
        func \(retryFunctionName)(\(parameters.map { $0.description }.joined(separator: ", "))) async throws -> \(returnType) {
            var attempt = 1
            var delay = \(baseDelay)
            
            while true {
                try Task.checkCancellation()
                do {
                    return try await \(functionName)(\(parameterCallString))
                } catch {
                    guard attempt < \(maxAttempts), \(shouldRetryClosure)(error, attempt) else { throw error }
                    let jitterFactor = 1 + Double.random(in: \(jitter))
                    let wait = min(\(maxDelay), delay) * jitterFactor
                    try await Task.sleep(nanoseconds: UInt64(wait * 1_000_000_000))
                    delay *= 2
                    attempt += 1
                }
            }
        }
        """
        
        return [DeclSyntax(stringLiteral: retryableFunction)]
    }
    
    private static func extractParameter(from node: AttributeSyntax, name: String, defaultValue: String) -> String {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else { return defaultValue }
        
        for argument in arguments {
            if argument.label?.text == name {
                return argument.expression.description
            }
        }
        
        return defaultValue
    }
    
    private static func extractShouldRetryClosure(from node: AttributeSyntax) -> String {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else { return "{ _, _ in true }" }
        
        for argument in arguments {
            if argument.label?.text == "shouldRetry" {
                return argument.expression.description
            }
        }
        
        return "{ _, _ in true }"
    }
}

struct MacroError: Error, CustomStringConvertible {
    let message: String
    
    init(_ message: String) {
        self.message = message
    }
    
    var description: String {
        message
    }
}

@main
struct RetryableMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        RetryableMacro.self,
        RetryableWithConditionMacro.self
    ]
}
