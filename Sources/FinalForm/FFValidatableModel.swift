//
//  FFValidatableModel.swift
//  FinalForm
//
//  Created by Lex Brouwers on 14/08/2025.
//

import SwiftUI

public protocol FFValidatableModel: Codable, Equatable, Hashable {
    associatedtype FieldType: FFValidatableField where FieldType.ModelType == Self
    var invalidFields: [FieldType] { get set }
    var requiredFields: [FieldType] { get }
    var forceValidatedFields: [FieldType] { get }
    var hasAnyValue: Bool { get }
}

enum ValidationMode {
    case onChange
    case onSave

    func shouldValidate(using model: any FFValidatableModel) -> Bool {
        switch self {
        case .onChange:
            return !model.invalidFields.isEmpty
        default:
            return true
        }
    }
}

extension Array where Element: FFValidatableModel {
    var hasAnyValue: Bool {
        for model in self where model.hasAnyValue {
            return true
        }

        return false
    }

    @discardableResult
    mutating func validateAll(_ mode: ValidationMode) -> Bool {
        var isValid = true
        for index in self.indices where !self[index].validate(mode) {
            isValid = false
        }

        return isValid
    }
}

extension FFValidatableModel {
    /// Check whether the model as a whole is valid. It gathers invalid fields and stores them.
    /// If the requiredFields are all valid, the model is valid, and this returns `true`.
    @discardableResult
    mutating func validate(_ mode: ValidationMode) -> Bool {
        guard mode.shouldValidate(using: self) else {
            return true
        }

        var invalidFields: [FieldType] = []
        validatedFields.forEach {
            if !$0.isValid(using: self) {
                invalidFields.append($0)
            }
        }

        self.invalidFields = invalidFields
        return invalidFields.isEmpty
    }

    /// Don't force any field validation by default.
    var forceValidatedFields: [FieldType] {
        []
    }

    /// Returns all fields that should be validated, those required and those forcibly validated.
    var validatedFields: [FieldType] {
        requiredFields + forceValidatedFields
    }

    /// Returns `true` if the model as a whole is completed.
    var isValid: Bool {
        validatedFields.areAllValid(using: self)
    }

    /// Returns `false` if the model as a whole is completed, `true` if invalid.
    var isNotValid: Bool {
        !isValid
    }

    /// Returns `true` when the given field needs validation.
    func shouldValidate(_ field: FieldType) -> Bool {
        validatedFields.contains(field)
    }

    /// Returns `true` when the given field is required.
    func requires(_ field: FieldType) -> Bool {
        requiredFields.contains(field)
    }

    /// Returns `true` when the given field is still invalid and should continue to show invalid feedback.
    func stillInvalid(_ field: FieldType) -> Bool {
       invalidFields.stillInvalid(field: field, using: self)
    }

    /// Returns whether model has any relevant value.
    /// This is used to use alternative data instead in the Scope & Goals vs Project Plan comparison.
    /// Returns `true` by default so other models don't have to worry about conformance.
    var hasAnyValue: Bool {
        true
    }

    /// Returns `true` when the given email is valid, and if required, not empty. If not required, allows for it to be empty.
    func checkEmail(_ field: FieldType, value: String) -> Bool {
        if requires(field) {
            return !value.isEmpty && value.isValidEmail
        } else {
            return value.isEmpty || value.isValidEmail
        }
    }

    /// Returns `true` when the given phone number is valid, and if required, not empty. If not required, allows for it to be empty.
    func checkPhoneNumber(_ field: FieldType, value: String) -> Bool {
        if requires(field) {
            return !value.isEmpty && value.isValidPhoneNumber
        } else {
            return value.isEmpty || value.isValidPhoneNumber
        }
    }

    /// Checks whether given email is valid and returns appropriate feedback string if necessary.
    func emailFeedback(_ field: FieldType, value: String) -> LocalizedStringKey? {
        if value.isEmpty {
            if requires(field) {
                return ""
            } else {
                return nil
            }
        } else if !value.isValidEmail {
            return Translation.Common.invalidEmail.rawValue
        }

        return nil
    }

    /// Show default errorFeedback footer when appropriate.
    @ViewBuilder
    func errorFeedbackFooterView(overrideText: LocalizedStringKey? = nil) -> some View {
        if (!invalidFields.isEmpty && isNotValid) || overrideText != nil {
            HStack {
                Spacer()
                ErrorFeedbackView(overrideText ?? Translation.Common.fillOutRequiredFields.rawValue)
            }
        }
    }
}
