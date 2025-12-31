//
//  ProjectRepositoryTests.swift
//  OffloadTests
//
//  Created by Claude Code on 12/31/24.
//

import XCTest
import SwiftData
@testable import offload

@MainActor
final class ProjectRepositoryTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var repository: ProjectRepository!

    override func setUpWithError() throws {
        // Create in-memory model container for testing
        let schema = Schema([
            Task.self,
            Project.self,
            Tag.self,
            Category.self,
            Thought.self
        ])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        modelContext = modelContainer.mainContext
        repository = ProjectRepository(modelContext: modelContext)
    }

    override func tearDownWithError() throws {
        repository = nil
        modelContext = nil
        modelContainer = nil
    }

    // MARK: - Create Tests

    func testCreateProject() throws {
        // Given
        let project = Project(name: "Test Project")

        // When
        try repository.create(project: project)

        // Then
        let allProjects = try repository.fetchAll()
        XCTAssertEqual(allProjects.count, 1)
        XCTAssertEqual(allProjects.first?.name, "Test Project")
    }

    func testCreateProjectWithMetadata() throws {
        // Given
        let project = Project(
            name: "Detailed Project",
            notes: "Project notes",
            color: "#FF5733",
            icon: "folder.fill"
        )

        // When
        try repository.create(project: project)

        // Then
        let allProjects = try repository.fetchAll()
        XCTAssertEqual(allProjects.first?.name, "Detailed Project")
        XCTAssertEqual(allProjects.first?.notes, "Project notes")
        XCTAssertEqual(allProjects.first?.color, "#FF5733")
        XCTAssertEqual(allProjects.first?.icon, "folder.fill")
    }

    // MARK: - Fetch Tests

    func testFetchAll() throws {
        // Given
        try repository.create(project: Project(name: "Project 1"))
        try repository.create(project: Project(name: "Project 2"))
        try repository.create(project: Project(name: "Project 3"))

        // When
        let projects = try repository.fetchAll()

        // Then
        XCTAssertEqual(projects.count, 3)
    }

    func testFetchActive() throws {
        // Given
        try repository.create(project: Project(name: "Active Project 1"))
        try repository.create(project: Project(name: "Active Project 2"))

        let archivedProject = Project(name: "Archived Project", archivedAt: Date())
        try repository.create(project: archivedProject)

        // When
        let activeProjects = try repository.fetchActive()

        // Then
        XCTAssertEqual(activeProjects.count, 2)
        XCTAssertTrue(activeProjects.allSatisfy { $0.archivedAt == nil })
        XCTAssertFalse(activeProjects.contains(where: { $0.name == "Archived Project" }))
    }

    func testFetchArchived() throws {
        // Given
        try repository.create(project: Project(name: "Active Project"))

        let archived1 = Project(name: "Archived 1", archivedAt: Date(timeIntervalSinceNow: -3600))
        let archived2 = Project(name: "Archived 2", archivedAt: Date())
        try repository.create(project: archived1)
        try repository.create(project: archived2)

        // When
        let archivedProjects = try repository.fetchArchived()

        // Then
        XCTAssertEqual(archivedProjects.count, 2)
        XCTAssertTrue(archivedProjects.allSatisfy { $0.archivedAt != nil })
        // Should be sorted by archivedAt descending (most recent first)
        XCTAssertEqual(archivedProjects.first?.name, "Archived 2")
    }

    func testFetchById() throws {
        // Given
        let project = Project(name: "Find Me")
        try repository.create(project: project)
        let projectId = project.id

        // When
        let foundProject = try repository.fetchById(projectId)

        // Then
        XCTAssertNotNil(foundProject)
        XCTAssertEqual(foundProject?.name, "Find Me")
        XCTAssertEqual(foundProject?.id, projectId)
    }

    func testFetchByIdNotFound() throws {
        // Given
        let randomId = UUID()

        // When
        let foundProject = try repository.fetchById(randomId)

        // Then
        XCTAssertNil(foundProject)
    }

    func testSearch() throws {
        // Given
        try repository.create(project: Project(
            name: "Mobile App",
            notes: "iOS development project"
        ))
        try repository.create(project: Project(
            name: "Web App",
            notes: "React development"
        ))
        try repository.create(project: Project(
            name: "Backend API",
            notes: "Mobile backend services"
        ))

        // When
        let results = try repository.search(query: "Mobile")

        // Then
        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(results.contains(where: { $0.name == "Mobile App" }))
        XCTAssertTrue(results.contains(where: { $0.name == "Backend API" }))
    }

    func testSearchByName() throws {
        // Given
        try repository.create(project: Project(name: "Shopping List"))
        try repository.create(project: Project(name: "Work Tasks"))
        try repository.create(project: Project(name: "Shopping Cart Feature"))

        // When
        let results = try repository.search(query: "Shopping")

        // Then
        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(results.allSatisfy { $0.name.contains("Shopping") })
    }

    func testSearchNoResults() throws {
        // Given
        try repository.create(project: Project(name: "Project A"))
        try repository.create(project: Project(name: "Project B"))

        // When
        let results = try repository.search(query: "NonExistent")

        // Then
        XCTAssertEqual(results.count, 0)
    }

    // MARK: - Update Tests

    func testUpdateProject() throws {
        // Given
        let project = Project(name: "Original Name")
        try repository.create(project: project)
        let originalUpdatedAt = project.updatedAt

        // Small delay to ensure updatedAt changes
        Thread.sleep(forTimeInterval: 0.01)

        // When
        project.name = "Updated Name"
        project.notes = "Added notes"
        try repository.update(project: project)

        // Then
        let allProjects = try repository.fetchAll()
        XCTAssertEqual(allProjects.first?.name, "Updated Name")
        XCTAssertEqual(allProjects.first?.notes, "Added notes")
        XCTAssertGreaterThan(allProjects.first!.updatedAt, originalUpdatedAt)
    }

    // MARK: - Archive Tests

    func testArchiveProject() throws {
        // Given
        let project = Project(name: "Project to Archive")
        try repository.create(project: project)
        XCTAssertNil(project.archivedAt)

        // When
        try repository.archive(project: project)

        // Then
        XCTAssertNotNil(project.archivedAt)
        XCTAssertNotNil(project.updatedAt)

        let archivedProjects = try repository.fetchArchived()
        XCTAssertEqual(archivedProjects.count, 1)

        let activeProjects = try repository.fetchActive()
        XCTAssertEqual(activeProjects.count, 0)
    }

    // MARK: - Delete Tests

    func testDeleteProject() throws {
        // Given
        let project = Project(name: "Project to Delete")
        try repository.create(project: project)
        XCTAssertEqual(try repository.fetchAll().count, 1)

        // When
        try repository.delete(project: project)

        // Then
        XCTAssertEqual(try repository.fetchAll().count, 0)
    }

    func testDeleteProjectWithTasks() throws {
        // Given
        let project = Project(name: "Project with Tasks")
        try repository.create(project: project)

        let task1 = Task(title: "Task 1", project: project)
        let task2 = Task(title: "Task 2", project: project)
        modelContext.insert(task1)
        modelContext.insert(task2)
        try modelContext.save()

        // When
        try repository.delete(project: project)

        // Then
        // Project should be deleted
        XCTAssertEqual(try repository.fetchAll().count, 0)

        // Tasks should still exist but with nil project (nullify delete rule)
        let taskDescriptor = FetchDescriptor<Task>()
        let remainingTasks = try modelContext.fetch(taskDescriptor)
        XCTAssertEqual(remainingTasks.count, 2)
        XCTAssertTrue(remainingTasks.allSatisfy { $0.project == nil })
    }

    // MARK: - Relationship Tests

    func testProjectWithTasks() throws {
        // Given
        let project = Project(name: "Test Project")
        try repository.create(project: project)

        let task1 = Task(title: "Task 1", project: project)
        let task2 = Task(title: "Task 2", project: project)
        modelContext.insert(task1)
        modelContext.insert(task2)
        try modelContext.save()

        // When
        let fetchedProject = try repository.fetchAll().first

        // Then
        XCTAssertNotNil(fetchedProject)
        XCTAssertEqual(fetchedProject?.tasks?.count, 2)
    }

    func testProjectHierarchy() throws {
        // Given
        let parentProject = Project(name: "Parent Project")
        try repository.create(project: parentProject)

        let childProject = Project(name: "Child Project", parentProject: parentProject)
        try repository.create(project: childProject)

        // When
        let fetchedChild = try repository.fetchById(childProject.id)

        // Then
        XCTAssertNotNil(fetchedChild)
        XCTAssertEqual(fetchedChild?.parentProject?.id, parentProject.id)
        XCTAssertEqual(fetchedChild?.parentProject?.name, "Parent Project")
    }

    // MARK: - Sorting Tests

    func testFetchAllSortedByCreatedAt() throws {
        // Given
        let old = Date(timeIntervalSinceNow: -7200)
        let recent = Date()

        let project1 = Project(name: "Old Project")
        project1.createdAt = old
        let project2 = Project(name: "Recent Project")
        project2.createdAt = recent

        try repository.create(project: project1)
        try repository.create(project: project2)

        // When
        let projects = try repository.fetchAll()

        // Then
        // Should be sorted by createdAt descending (most recent first)
        XCTAssertEqual(projects.first?.name, "Recent Project")
        XCTAssertEqual(projects.last?.name, "Old Project")
    }

    func testFetchActiveSortedByUpdatedAt() throws {
        // Given
        let old = Date(timeIntervalSinceNow: -3600)
        let recent = Date()

        let project1 = Project(name: "Updated Recently")
        project1.updatedAt = recent
        let project2 = Project(name: "Updated Long Ago")
        project2.updatedAt = old

        try repository.create(project: project1)
        try repository.create(project: project2)

        // When
        let activeProjects = try repository.fetchActive()

        // Then
        // Should be sorted by updatedAt descending (most recent first)
        XCTAssertEqual(activeProjects.first?.name, "Updated Recently")
        XCTAssertEqual(activeProjects.last?.name, "Updated Long Ago")
    }

    // MARK: - Performance Tests

    func testFetchPerformanceWith100Projects() throws {
        // Given: Create 100 projects
        for i in 1...100 {
            try repository.create(project: Project(name: "Project \(i)"))
        }

        // When/Then: Measure fetch performance
        measure {
            _ = try? repository.fetchAll()
        }
    }

    func testSearchPerformanceWith100Projects() throws {
        // Given: Create 100 projects with varying names
        for i in 1...100 {
            let prefix = i % 2 == 0 ? "Mobile" : "Web"
            try repository.create(project: Project(name: "\(prefix) Project \(i)"))
        }

        // When/Then: Measure search performance
        measure {
            _ = try? repository.search(query: "Mobile")
        }
    }
}
