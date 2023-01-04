//: [Previous](@previous)

import SwiftUI

// MARK: - Unstructured Concurrency の Task.init と Task.detached

// MARK: Task.init について

struct TaskView: View {
    @ObservedObject
    private var viewModel = TaskViewModel()

    var body: some View {
        Button {
            viewModel.forceCancel()
        } label: {
            Text("forceCancel")
        }
        .onAppear {
            viewModel.fetchUser()
        }
    }
}

final class TaskViewModel: ObservableObject {
    // 後で別のメソッドからキャンセルできるようにインスタンスを保持.
    var task: Task<Void, Never>? = nil

    func fetchUser() {
        // `Task` のインスタンスを保持しているため、生存期間はイニシャライザー実行時のスコープを超える可能性がある.
        task = Task {
            let users = await longTask()
            print(users)
        }
    }

    func forceCancel() {
        guard let task = task else { return }
        // 保持している `Task` をキャンセル.
        task.cancel()
    }

    private func longTask() async -> [String] {
        try? await Task.sleep(nanoseconds: NSEC_PER_MSEC * 3)
        return ["A", "B", "C"]
    }
}

/// `Task.init` での階層構造について.
actor A {
    func runTask() {
        // 親タスクを `TaskPriority.high` で作成.
        let parent = Task(priority: .high) {
            let child = Task {
                // 子タスクは `TaskPriority.high` を引き継ぐ.
                // 子タスクがキャンセルしても、親タスクが自動でキャンセルされるわけではない.
            }
        }
    }
}

// MARK: Task.detached

/// `Task.detached` の利用シーンについて.
///
/// MainActor 内でメインスレッドで実行しなくても良い処理を実行したい場合など.
@MainActor
final class TaskDetachedViewModel: ObservableObject {
    // `MainActor` がこのクラスについているので、このメソッドはメインスレッドで実行される.
    func didTapButton() {
        Task {
            Task.detached(priority: .low) { [weak self] in
                // ここはメインスレッドでは実行されない.
                guard let self = self else { return }
                async let _ = await self.sendLog(with: "didTapButton")
                async let _ = await self.sendLog(with: "user is A")
            }

            // ここは `Task.init` のクロージャーになるためメインスレッドで実行される.
            let users = await fetchUsers()
            print(users)
        }
    }

    private func fetchUsers() async -> [String] {
        try? await Task.sleep(nanoseconds: NSEC_PER_MSEC * 3)
        return ["A", "B", "C"]
    }

    private func sendLog(with name: String) async {
        try? await Task.sleep(nanoseconds: NSEC_PER_MSEC * 1)
        print(name)
    }
}

//: [Next](@next)
