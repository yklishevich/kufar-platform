import XCTest
import SessionInterface
import SessionInterfaceTesting

final class SessionTests: XCTestCase {

    func testUpdatesDeliverStateChanges() async {
        let session = StubSession(.signedIn("42"))
        var received: [SessionState] = []

        let task = Task {
            for await state in session.updates {
                received.append(state)
                if received.count == 2 { break }
            }
        }

        await session.restore()
        session.signOut()
        await task.value

        XCTAssertEqual(received.first, .signedIn("42"))
        XCTAssertEqual(received.last, .signedOut)
    }
}
