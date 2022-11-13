//: [Main](@previous)

import Foundation

// MARK: - 1.5 順列実行と並列実行
//
// 非同期処理を順列、並列にそれぞれどのように実行するのか.

/// 同期関数の順列実行.
///
/// 今までの同期関数の場合、クロージャーをネストさせることで順列実行を表現できる.
enum ExecuteSyncMethodSerial {
    func runAsSequence() {
        /// 適当な非同期処理.
        func _waitOneSecond(completion: @escaping (() -> Void)) {
            completion()
        }

        // コールバック内で非同期処理を実行していくこと.
        _waitOneSecond {
            _waitOneSecond {
                _waitOneSecond {
                    // do something
                }
            }
        }
    }
}

/// async/await を使った非同期関数の順列実行.
///
/// await キーワードをつけてそれぞれ順々に呼び出せばいいだけ.
enum ExecuteAsyncMethodSerial {
    func runAsSequence() async {
        /// 適当な非同期処理.
        func _waitOneSecond() async {}

        // ネストなしで表現できる.
        await _waitOneSecond()
        await _waitOneSecond()
        await _waitOneSecond()
    }
}

/// 同期関数の並列実行.
///
/// `DispatchGroup` を利用して並列実行を表現できる.
enum ExecuteSyncMethodParallel {
    func runAsParallel(completion: @escaping (() -> Void)) {
        /// 適当な非同期処理.
        func _waitOnSecond(completion: @escaping (() -> Void)) {
            completion()
        }

        let group = DispatchGroup()

        // enter と leave を行うことを忘れないようにしないといけない.
        group.enter()
        _waitOnSecond {
            group.leave()
        }

        group.enter()
        _waitOnSecond {
            group.leave()
        }

        group.enter()
        _waitOnSecond {
            group.leave()
        }

        group.notify(queue: .global()) {
            // 全部の処理が終わったので、完了を通知.
            completion()
        }
    }
}

/// 非同期関数の並列実行.
///
/// async なメソッドの場合は、非同期関数の戻り値を `async let` で定義することで並列実行を表現できる.
enum ExecuteAsyncMethodParallel {
    func runAsParallel() async {
        /// 適当な非同期処理.
        /// `Concurrently-executed local function '_waitOneSecond()' must be marked as '@Sendable'` らしい.
        @Sendable func _waitOneSecond() async {}

        // async let で定義することで、次のメソッドの完了を待たずに次の行に移る.
        async let first: Void = _waitOneSecond()
        async let second: Void = _waitOneSecond()
        async let third: Void = _waitOneSecond()

        await first
        await second
        await third
    }
}

//: [Next](@next)
