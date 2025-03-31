import Foundation

// This file exists only for compatibility with existing references.
// All functionality has been moved to SupabaseService.swift.
// This file will be deleted in future refactorings.

#if false
// The code below is commented out but kept for reference
func ensurePatReportsTableExists() async throws {
    try await SupabaseController.shared.ensurePatReportsTableExists()
}

func insertSamplePatientReport() async throws {
    try await SupabaseController.shared.insertSamplePatientReport()
}
#endif 

// Delegate to the shared instance
func insert<T: Encodable>(into table: String, data: T) async throws {
    try await SupabaseController.shared.insert(into: table, data: data)
} 