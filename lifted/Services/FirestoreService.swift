import Foundation
import FirebaseFirestore

enum FirestoreCollection: String {
    case users
    case exercises
    case schedules = "schedule"
    case progressionPlans = "progressionPlan"
    case exerciseProgressions = "exerciseProgressions"
    case workoutSessions = "workoutSessions"
    case personalRecords = "personalRecords"
    case trainerNotes = "trainerNotes"
    case trainerChats = "trainerChats"
}

actor FirestoreService {
    static let shared = FirestoreService()
    private let db = Firestore.firestore()

    private init() {}

    // MARK: - Generic CRUD Operations

    func create<T: Codable>(_ object: T, collection: FirestoreCollection, documentId: String? = nil) async throws -> String {
        let collectionRef = db.collection(collection.rawValue)
        let data = try Firestore.Encoder().encode(object)

        if let documentId = documentId {
            try await collectionRef.document(documentId).setData(data)
            return documentId
        } else {
            let ref = try await collectionRef.addDocument(data: data)
            return ref.documentID
        }
    }

    func createInSubcollection<T: Codable>(
        _ object: T,
        parentCollection: FirestoreCollection,
        parentId: String,
        subcollection: FirestoreCollection,
        documentId: String? = nil
    ) async throws -> String {
        let collectionRef = db.collection(parentCollection.rawValue)
            .document(parentId)
            .collection(subcollection.rawValue)
        let data = try Firestore.Encoder().encode(object)

        if let documentId = documentId {
            try await collectionRef.document(documentId).setData(data)
            return documentId
        } else {
            let ref = try await collectionRef.addDocument(data: data)
            return ref.documentID
        }
    }

    func read<T: Codable>(collection: FirestoreCollection, documentId: String) async throws -> T? {
        let document = try await db.collection(collection.rawValue).document(documentId).getDocument()
        guard document.exists else { return nil }
        return try document.data(as: T.self)
    }

    func readFromSubcollection<T: Codable>(
        parentCollection: FirestoreCollection,
        parentId: String,
        subcollection: FirestoreCollection,
        documentId: String
    ) async throws -> T? {
        let document = try await db.collection(parentCollection.rawValue)
            .document(parentId)
            .collection(subcollection.rawValue)
            .document(documentId)
            .getDocument()
        guard document.exists else { return nil }
        return try document.data(as: T.self)
    }

    func readAll<T: Codable>(collection: FirestoreCollection) async throws -> [T] {
        let snapshot = try await db.collection(collection.rawValue).getDocuments()
        return try snapshot.documents.compactMap { try $0.data(as: T.self) }
    }

    func readAllFromSubcollection<T: Codable>(
        parentCollection: FirestoreCollection,
        parentId: String,
        subcollection: FirestoreCollection
    ) async throws -> [T] {
        let snapshot = try await db.collection(parentCollection.rawValue)
            .document(parentId)
            .collection(subcollection.rawValue)
            .getDocuments()
        return try snapshot.documents.compactMap { try $0.data(as: T.self) }
    }

    func update<T: Codable>(_ object: T, collection: FirestoreCollection, documentId: String) async throws {
        let data = try Firestore.Encoder().encode(object)
        try await db.collection(collection.rawValue).document(documentId).setData(data, merge: true)
    }

    func updateInSubcollection<T: Codable>(
        _ object: T,
        parentCollection: FirestoreCollection,
        parentId: String,
        subcollection: FirestoreCollection,
        documentId: String
    ) async throws {
        let data = try Firestore.Encoder().encode(object)
        try await db.collection(parentCollection.rawValue)
            .document(parentId)
            .collection(subcollection.rawValue)
            .document(documentId)
            .setData(data, merge: true)
    }

    func delete(collection: FirestoreCollection, documentId: String) async throws {
        try await db.collection(collection.rawValue).document(documentId).delete()
    }

    func deleteFromSubcollection(
        parentCollection: FirestoreCollection,
        parentId: String,
        subcollection: FirestoreCollection,
        documentId: String
    ) async throws {
        try await db.collection(parentCollection.rawValue)
            .document(parentId)
            .collection(subcollection.rawValue)
            .document(documentId)
            .delete()
    }

    // MARK: - Query Operations

    func query<T: Codable>(
        collection: FirestoreCollection,
        field: String,
        isEqualTo value: Any
    ) async throws -> [T] {
        let snapshot = try await db.collection(collection.rawValue)
            .whereField(field, isEqualTo: value)
            .getDocuments()
        return try snapshot.documents.compactMap { try $0.data(as: T.self) }
    }

    func queryFromSubcollection<T: Codable>(
        parentCollection: FirestoreCollection,
        parentId: String,
        subcollection: FirestoreCollection,
        field: String,
        isEqualTo value: Any
    ) async throws -> [T] {
        let snapshot = try await db.collection(parentCollection.rawValue)
            .document(parentId)
            .collection(subcollection.rawValue)
            .whereField(field, isEqualTo: value)
            .getDocuments()
        return try snapshot.documents.compactMap { try $0.data(as: T.self) }
    }

    func queryDateRange<T: Codable>(
        parentCollection: FirestoreCollection,
        parentId: String,
        subcollection: FirestoreCollection,
        dateField: String,
        startDate: Date,
        endDate: Date
    ) async throws -> [T] {
        let snapshot = try await db.collection(parentCollection.rawValue)
            .document(parentId)
            .collection(subcollection.rawValue)
            .whereField(dateField, isGreaterThanOrEqualTo: startDate)
            .whereField(dateField, isLessThanOrEqualTo: endDate)
            .getDocuments()
        return try snapshot.documents.compactMap { try $0.data(as: T.self) }
    }

    // MARK: - User-Specific Operations

    func getUser(userId: String) async throws -> User? {
        try await read(collection: .users, documentId: userId)
    }

    func saveUser(_ user: User) async throws {
        // Use create instead of update to ensure document is properly created
        // The documentId parameter ensures we use the user's ID
        _ = try await create(user, collection: .users, documentId: user.id)
    }

    func getActiveSchedule(userId: String) async throws -> WorkoutSchedule? {
        let schedules: [WorkoutSchedule] = try await queryFromSubcollection(
            parentCollection: .users,
            parentId: userId,
            subcollection: .schedules,
            field: "isActive",
            isEqualTo: true
        )
        return schedules.first
    }

    func getProgressionPlan(userId: String) async throws -> ProgressionPlan? {
        let plans: [ProgressionPlan] = try await readAllFromSubcollection(
            parentCollection: .users,
            parentId: userId,
            subcollection: .progressionPlans
        )
        return plans.first
    }

    func getExerciseProgressions(userId: String) async throws -> [ExerciseProgression] {
        try await readAllFromSubcollection(
            parentCollection: .users,
            parentId: userId,
            subcollection: .exerciseProgressions
        )
    }

    func getWorkoutSessions(userId: String, startDate: Date, endDate: Date) async throws -> [WorkoutSession] {
        try await queryDateRange(
            parentCollection: .users,
            parentId: userId,
            subcollection: .workoutSessions,
            dateField: "scheduledDate",
            startDate: startDate,
            endDate: endDate
        )
    }

    func getTrainerNotes(userId: String, activeOnly: Bool = true) async throws -> [TrainerNote] {
        if activeOnly {
            return try await queryFromSubcollection(
                parentCollection: .users,
                parentId: userId,
                subcollection: .trainerNotes,
                field: "isActive",
                isEqualTo: true
            )
        } else {
            return try await readAllFromSubcollection(
                parentCollection: .users,
                parentId: userId,
                subcollection: .trainerNotes
            )
        }
    }

    func getPersonalRecords(userId: String) async throws -> [PersonalRecord] {
        try await readAllFromSubcollection(
            parentCollection: .users,
            parentId: userId,
            subcollection: .personalRecords
        )
    }

    func getAllExercises() async throws -> [Exercise] {
        try await readAll(collection: .exercises)
    }
}
