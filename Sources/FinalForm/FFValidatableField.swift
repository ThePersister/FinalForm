//
//  FFValidatableField.swift
//  FinalForm
//
//  Created by Lex Brouwers on 14/08/2025.
//

import SwiftUI

public protocol FFValidatableField: Codable, Equatable, RawRepresentable where RawValue == String {
    associatedtype ModelType: FFValidatableModel
    func isValid(using form: ModelType) -> Bool
    var label: LocalizedStringKey? { get }
    var placeholder: LocalizedStringKey { get }
    var keyboardType: UIKeyboardType { get }
    var autoCapitalization: TextInputAutocapitalization { get }
    func feedback(using form: ModelType) -> LocalizedStringKey?
    var charLimit: Int? { get }
    var inputStyle: InputStyle { get }
    var inputAlignment: TextAlignment { get }
}

extension FFValidatableField {
    /// Provides default inputStyle `.separatorBottom`, can be overridden.
    var inputStyle: InputStyle {
        .separatorBottom
    }

    /// Provides default text alignment `.trailing`, can be overridden.
    /// Some views may prefer `.leading`, like `SetScopeView`'s rows.
    var inputAlignment: TextAlignment {
        .trailing
    }

    /// Provides default keyboardType `.default`, can be overridden.
    var keyboardType: UIKeyboardType {
        .default
    }

    /// Provides default autoCapitalization `.sentences`, can be overridden.
    var autoCapitalization: TextInputAutocapitalization {
        .sentences
    }

    /// Provides default charLimit `nil`, can be overridden.
    var charLimit: Int? {
        nil
    }

    /// Convenience method to check whether field is invalid using model.
    public func isInvalid(using form: ModelType) -> Bool {
        !isValid(using: form)
    }

    /// Provides default feedback `""`, can be overridden.
    /// By default we use an empty string instead of nil, this shows the red error feedback, but no text message.
    public func feedback(using model: ModelType) -> LocalizedStringKey? {
        ""
    }
}

extension Array where Element: FFValidatableField {
    func areAllValid(using form: Element.ModelType) -> Bool {
        return !self.hasAnyStillInvalid(using: form)
    }

    func stillInvalid(field: Element, using form: Element.ModelType) -> Bool {
        return self.contains { $0.rawValue == field.rawValue && field.isInvalid(using: form) }
    }

    func hasAnyStillInvalid(using form: Element.ModelType) -> Bool {
        for field in self where field.isInvalid(using: form) {
            return true
        }
        return false
    }
}
