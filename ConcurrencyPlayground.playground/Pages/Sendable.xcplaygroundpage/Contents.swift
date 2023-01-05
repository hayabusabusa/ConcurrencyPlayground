//: [Previous](@previous)

import Foundation

// MARK: - Sendable

/// `Sendable` な型にすることでデータ競合が起こらないことをコンパイル時に保証できる.
///
/// `Sendable` にするには `Sendable` プロトコルや `@Sendable` を利用する.
/// また、`Sendable` はマーカープロトコルなので、`is` やダウンキャストができない.
struct A: Sendable {}

let a = A()
// error: marker protocol 'Sendable' cannot be used in a conditional cast
//print(a is Sendable)

actor SomeActor {
    /// `Sendable` ではないデータを定義するのは OK.
    func doSomething(to string: NSMutableString) -> NSMutableString {
        return string
    }
}

/// Actor 外から `Sendable` ではないデータを渡すとどうなるか.
func someFunc(actor: SomeActor, string: NSMutableString) async {
    // Actor 外で Sendable ではない NSMutableString を渡すとワーニング.
    // Non-sendable type 'NSMutableString' passed in implicitly asynchronous call to actor-isolated instance method 'doSomething(to:)' cannot cross actor boundary
    let result = await actor.doSomething(to: string)
    print(result)
}

// MARK: Sendable プロトコル

/// メンバーが全て `Sendable` に準拠していれば OK.
/// `String` などのメタタイプはすでに `Sendable` に準拠している.
struct SendableOK: Sendable {
    let title: String
    let message: String
}

/// メンバーが  `Sendable` に準拠していないものがある場合は NG.
/// `NSString` は `Sendable` に準拠していない.
struct SendableNG: Sendable {
    var title: String
//    var message: NSString
}

/// 型パラメーターが存在する場合はその型パラメーター `T` が `Sendable` に準拠していないとダメ.
struct GenericType<T>: Sendable {
//    var a: T
}

struct ConfirmSendable<T> {
    var a: T
}

/// `where` を利用して型パラメーターが `Sendable` に準拠している場合にのみ `Sendable` に適応させる.
/// また、extension で準拠させる場合は同じファイルで定義が必要.
extension ConfirmSendable: Sendable where T: Sendable {}

// MARK: 暗黙的な Sendable 準拠

/// `public` 指定でない場合は暗黙的に `Sendable` 準拠になる.
///
/// ただし、自動的に `Sendable` に準拠できない場合は外れる,
struct Person1 {
    var name: String
    var age: Int
}

/// `public` 指定の場合は暗黙的に準拠しない.
public struct Person2 {
    var name: String
    var age: Int
}

/// `@frozen` の指定がある場合は `public` でも暗黙的に準拠.
@frozen
public struct Person3 {
    var name: String
}

/// 型パラメーターの `Item` が `Sendable` なので `Box` も暗黙的に `Sendable`.
struct Box<Item: Sendable> {
    var item: Item
}

/// 型パラメーターの `Item` に `Sendable` の指定がないので `Box2` は暗黙的に `Sendable` にならない.
struct Box2<Item> {
    var item: Item
}

/// 明示的に `Sendable` に準拠させることは可能.
extension Box2: Sendable where Item: Sendable {}

/// `class` の場合は `final` かつ普遍データのストアドプロパティを持つ class のみコンパイル時にチェックが通る.
///
/// 手動でデータ競合を管理するクラスを作る場合は `@unchecked` 属性をつけることで自前で管理することができるようになる.
/// ただし、コンパイラのチェックがなくなるので注意が必要.
final class SendableClass: Sendable {
    let name: String

    init(name: String) {
        self.name = name
    }
}

/// 本来は `final` なクラスではないのでコンパイラに注意されるが、`@unchecked` がついているのでコンパイラにチェックされなくなる.
class SendableClass2: @unchecked Sendable {}

//: [Next](@next)
